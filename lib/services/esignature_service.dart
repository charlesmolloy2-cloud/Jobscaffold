import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
// import '../services/storage_service.dart';

/// Digital signature and contract management service
class ESignatureService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // StorageService not required for signature bytes upload; using FirebaseStorage directly

  /// Create a new contract
  Future<String> createContract({
    required String projectId,
    required String title,
    required String content,
    required List<String> signerIds,
    String? pdfUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final contractRef = _firestore.collection('contracts').doc();

    final contract = Contract(
      id: contractRef.id,
      projectId: projectId,
      title: title,
      content: content,
      createdBy: currentUser.uid,
      createdAt: DateTime.now(),
      signerIds: signerIds,
      signatures: {},
      status: ContractStatus.pending,
      pdfUrl: pdfUrl,
      metadata: metadata ?? {},
    );

    await contractRef.set(contract.toMap());

    // Create notifications for signers
    for (final signerId in signerIds) {
      if (signerId != currentUser.uid) {
        await _createSignatureRequest(contractRef.id, signerId, title);
      }
    }

    return contractRef.id;
  }

  /// Save signature to contract
  Future<void> signContract({
    required String contractId,
    required Uint8List signatureImage,
    String? signedName,
    String? ipAddress,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Upload signature image directly to Firebase Storage
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storageRef = FirebaseStorage.instance.ref(
      'signatures/$contractId/${currentUser.uid}_$timestamp.png',
    );
    final uploadTask = await storageRef.putData(
      signatureImage,
      SettableMetadata(
        contentType: 'image/png',
        customMetadata: {
          'uploadedBy': currentUser.uid,
          'contractId': contractId,
        },
      ),
    );
    final signatureUrl = await uploadTask.ref.getDownloadURL();

    final signature = Signature(
      userId: currentUser.uid,
      signedAt: DateTime.now(),
      signatureUrl: signatureUrl,
      signedName: signedName,
      ipAddress: ipAddress,
    );

    // Update contract with signature
    await _firestore.collection('contracts').doc(contractId).update({
      'signatures.${currentUser.uid}': signature.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Check if all signatures collected
    final contractDoc = await _firestore.collection('contracts').doc(contractId).get();
    final contract = Contract.fromFirestore(contractDoc);

    if (contract.isFullySigned) {
      await _firestore.collection('contracts').doc(contractId).update({
        'status': ContractStatus.completed.toString(),
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Generate final PDF
      await _generateFinalPDF(contract);

      // Notify contract creator
      await _notifyContractCompleted(contract);
    }
  }

  /// Get contracts for a project
  Stream<List<Contract>> getProjectContracts(String projectId) {
    return _firestore
        .collection('contracts')
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Contract.fromFirestore(doc)).toList();
    });
  }

  /// Get contracts requiring user's signature
  Stream<List<Contract>> getPendingContracts(String userId) {
    return _firestore
        .collection('contracts')
        .where('signerIds', arrayContains: userId)
        .where('status', isEqualTo: ContractStatus.pending.toString())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Contract.fromFirestore(doc))
          .where((contract) => !contract.signatures.containsKey(userId))
          .toList();
    });
  }

  /// Get contract by ID
  Future<Contract> getContract(String contractId) async {
    final doc = await _firestore.collection('contracts').doc(contractId).get();
    return Contract.fromFirestore(doc);
  }

  /// Delete/void a contract
  Future<void> voidContract(String contractId, String reason) async {
    await _firestore.collection('contracts').doc(contractId).update({
      'status': ContractStatus.voided.toString(),
      'voidReason': reason,
      'voidedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Resend signature request
  Future<void> resendSignatureRequest(String contractId, String signerId) async {
    final contract = await getContract(contractId);
    await _createSignatureRequest(contractId, signerId, contract.title);
  }

  /// Convert signature points to image
  Future<Uint8List> signatureToImage(
  List<List<SignatureOffset>> strokes,
  SignatureSize size,
  ) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

    // Draw white background
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.width, size.height),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );

    // Draw signature strokes
    final paint = ui.Paint()
      ..color = const ui.Color(0xFF000000)
      ..strokeWidth = 3.0
      ..strokeCap = ui.StrokeCap.round
      ..style = ui.PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;

      final path = ui.Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);

      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }

      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  Future<void> _createSignatureRequest(
    String contractId,
    String signerId,
    String contractTitle,
  ) async {
    await _firestore.collection('notifications').add({
      'userId': signerId,
      'title': 'Signature Required',
      'body': 'Please sign: $contractTitle',
      'type': 'contract_signature',
      'data': {
        'contractId': contractId,
      },
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _generateFinalPDF(Contract contract) async {
    // TODO: Integrate with PDF generation library (pdf package)
    // This would create a final PDF with all signatures embedded
    print('Generating final PDF for contract: ${contract.id}');
  }

  Future<void> _notifyContractCompleted(Contract contract) async {
    await _firestore.collection('notifications').add({
      'userId': contract.createdBy,
      'title': 'Contract Completed',
      'body': '${contract.title} has been fully signed',
      'type': 'contract_completed',
      'data': {
        'contractId': contract.id,
      },
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

/// Contract model
class Contract {
  final String id;
  final String projectId;
  final String title;
  final String content;
  final String createdBy;
  final DateTime createdAt;
  final List<String> signerIds;
  final Map<String, Signature> signatures;
  final ContractStatus status;
  final String? pdfUrl;
  final String? finalPdfUrl;
  final DateTime? completedAt;
  final String? voidReason;
  final Map<String, dynamic> metadata;

  Contract({
    required this.id,
    required this.projectId,
    required this.title,
    required this.content,
    required this.createdBy,
    required this.createdAt,
    required this.signerIds,
    required this.signatures,
    required this.status,
    this.pdfUrl,
    this.finalPdfUrl,
    this.completedAt,
    this.voidReason,
    required this.metadata,
  });

  bool get isFullySigned => signatures.length == signerIds.length;

  double get signatureProgress => signerIds.isEmpty ? 0 : (signatures.length / signerIds.length);

  List<String> get pendingSigners {
    return signerIds.where((id) => !signatures.containsKey(id)).toList();
  }

  factory Contract.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final signaturesMap = <String, Signature>{};
    if (data['signatures'] != null) {
      final sigs = data['signatures'] as Map<String, dynamic>;
      sigs.forEach((key, value) {
        signaturesMap[key] = Signature.fromMap(value as Map<String, dynamic>);
      });
    }

    return Contract(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      signerIds: List<String>.from(data['signerIds'] ?? []),
      signatures: signaturesMap,
      status: ContractStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => ContractStatus.pending,
      ),
      pdfUrl: data['pdfUrl'] as String?,
      finalPdfUrl: data['finalPdfUrl'] as String?,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      voidReason: data['voidReason'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    final signaturesMap = <String, dynamic>{};
    signatures.forEach((key, value) {
      signaturesMap[key] = value.toMap();
    });

    return {
      'projectId': projectId,
      'title': title,
      'content': content,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'signerIds': signerIds,
      'signatures': signaturesMap,
      'status': status.toString(),
      'pdfUrl': pdfUrl,
      'finalPdfUrl': finalPdfUrl,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'voidReason': voidReason,
      'metadata': metadata,
    };
  }
}

/// Signature model
class Signature {
  final String userId;
  final DateTime signedAt;
  final String signatureUrl;
  final String? signedName;
  final String? ipAddress;

  Signature({
    required this.userId,
    required this.signedAt,
    required this.signatureUrl,
    this.signedName,
    this.ipAddress,
  });

  factory Signature.fromMap(Map<String, dynamic> map) {
    return Signature(
      userId: map['userId'] ?? '',
      signedAt: (map['signedAt'] as Timestamp).toDate(),
      signatureUrl: map['signatureUrl'] ?? '',
      signedName: map['signedName'] as String?,
      ipAddress: map['ipAddress'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'signedAt': Timestamp.fromDate(signedAt),
      'signatureUrl': signatureUrl,
      'signedName': signedName,
      'ipAddress': ipAddress,
    };
  }
}

enum ContractStatus {
  draft,
  pending,
  completed,
  voided,
  expired,
}

class SignatureOffset {
  final double dx;
  final double dy;

  SignatureOffset(this.dx, this.dy);
}

class SignatureSize {
  final double width;
  final double height;

  SignatureSize(this.width, this.height);
}
