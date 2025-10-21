import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

/// Service for handling photo/file uploads to Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload a file to Firebase Storage and save metadata to Firestore
  /// 
  /// [file] - PlatformFile from file picker
  /// [userId] - ID of user uploading the file
  /// [projectId] - Optional project ID to associate the file with
  /// [description] - Optional description/note about the file
  /// 
  /// Returns the document ID of the file metadata in Firestore
  Future<String> uploadFile({
    required PlatformFile file,
    required String userId,
    String? projectId,
    String? description,
  }) async {
    try {
      // Create unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.extension ?? '';
      final fileName = 'file_${timestamp}${extension.isNotEmpty ? '.$extension' : ''}';
      
      // Create storage reference
      final storageRef = projectId != null
          ? _storage.ref('projects/$projectId/files/$fileName')
          : _storage.ref('uploads/$userId/$fileName');

      // Upload file
      UploadTask uploadTask;
      if (kIsWeb) {
        // Web: use bytes
        if (file.bytes != null) {
          uploadTask = storageRef.putData(
            file.bytes!,
            SettableMetadata(
              contentType: _getContentType(extension),
              customMetadata: {
                'uploadedBy': userId,
                'originalName': file.name,
              },
            ),
          );
        } else {
          throw Exception('File bytes are null');
        }
      } else {
        // Mobile: use file path
        final fileToUpload = File(file.path!);
        uploadTask = storageRef.putFile(
          fileToUpload,
          SettableMetadata(
            contentType: _getContentType(extension),
            customMetadata: {
              'uploadedBy': userId,
              'originalName': file.name,
            },
          ),
        );
      }

      // Wait for upload to complete
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save metadata to Firestore
      final metadata = {
        'fileName': file.name,
        'storagePath': storageRef.fullPath,
        'downloadUrl': downloadUrl,
        'uploadedBy': userId,
        'uploadedAt': FieldValue.serverTimestamp(),
        'size': file.size,
        'contentType': _getContentType(extension),
        'projectId': projectId,
        'description': description,
      };

      final docRef = await _firestore.collection('files').add(metadata);
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Get files for a specific project
  Stream<List<FileMetadata>> getProjectFiles(String projectId) {
    return _firestore
        .collection('files')
        .where('projectId', isEqualTo: projectId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FileMetadata.fromFirestore(doc))
            .toList());
  }

  /// Get all files uploaded by a user
  Stream<List<FileMetadata>> getUserFiles(String userId) {
    return _firestore
        .collection('files')
        .where('uploadedBy', isEqualTo: userId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FileMetadata.fromFirestore(doc))
            .toList());
  }

  /// Delete a file from Storage and Firestore
  Future<void> deleteFile(String fileId, String storagePath) async {
    try {
      // Delete from Storage
      await _storage.ref(storagePath).delete();
      
      // Delete metadata from Firestore
      await _firestore.collection('files').doc(fileId).delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Get content type based on file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }

  /// Check if file is an image
  bool isImage(String contentType) {
    return contentType.startsWith('image/');
  }
}

/// File metadata model
class FileMetadata {
  final String id;
  final String fileName;
  final String storagePath;
  final String downloadUrl;
  final String uploadedBy;
  final DateTime uploadedAt;
  final int size;
  final String contentType;
  final String? projectId;
  final String? description;

  FileMetadata({
    required this.id,
    required this.fileName,
    required this.storagePath,
    required this.downloadUrl,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.size,
    required this.contentType,
    this.projectId,
    this.description,
  });

  factory FileMetadata.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FileMetadata(
      id: doc.id,
      fileName: data['fileName'] ?? 'Unknown',
      storagePath: data['storagePath'] ?? '',
      downloadUrl: data['downloadUrl'] ?? '',
      uploadedBy: data['uploadedBy'] ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      size: data['size'] ?? 0,
      contentType: data['contentType'] ?? 'application/octet-stream',
      projectId: data['projectId'],
      description: data['description'],
    );
  }

  bool get isImage => contentType.startsWith('image/');

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
