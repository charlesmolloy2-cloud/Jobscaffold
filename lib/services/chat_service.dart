import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for real-time messaging/chat functionality
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get or create a conversation between two users
  Future<String> getOrCreateConversation(String userId1, String userId2) async {
    // Sort IDs to ensure consistent conversation ID
    final ids = [userId1, userId2]..sort();
    final conversationId = '${ids[0]}_${ids[1]}';

    final convRef = _firestore.collection('conversations').doc(conversationId);
    final doc = await convRef.get();

    if (!doc.exists) {
      await convRef.set({
        'participants': ids,
        'participantIds': ids,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageAt': null,
        'unreadCount': {userId1: 0, userId2: 0},
      });
    }

    return conversationId;
  }

  /// Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String text,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be signed in to send messages');

    final messageData = {
      'senderId': user.uid,
      'senderName': user.displayName ?? 'Unknown',
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    };

    // Add message to subcollection
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(messageData);

    // Update conversation metadata
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': user.uid,
    });

    // Increment unread count for recipient
    final convDoc = await _firestore.collection('conversations').doc(conversationId).get();
    final participants = List<String>.from(convDoc.data()?['participantIds'] ?? []);
    final recipientId = participants.firstWhere((id) => id != user.uid, orElse: () => '');
    
    if (recipientId.isNotEmpty) {
      await _firestore.collection('conversations').doc(conversationId).update({
        'unreadCount.$recipientId': FieldValue.increment(1),
      });
    }
  }

  /// Get messages stream for a conversation
  Stream<List<ChatMessage>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  /// Get all conversations for current user
  Stream<List<Conversation>> getConversations() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: user.uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Conversation.fromFirestore(doc))
            .toList());
  }

  /// Mark messages as read
  Future<void> markAsRead(String conversationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Reset unread count
    await _firestore.collection('conversations').doc(conversationId).update({
      'unreadCount.${user.uid}': 0,
    });

    // Mark unread messages as read
    final unreadMessages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('read', isEqualTo: false)
        .where('senderId', isNotEqualTo: user.uid)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  /// Set typing indicator
  Future<void> setTyping(String conversationId, bool isTyping) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('conversations').doc(conversationId).update({
      'typing.${user.uid}': isTyping,
      'typingAt.${user.uid}': FieldValue.serverTimestamp(),
    });
  }

  /// Get typing status stream
  Stream<Map<String, bool>> getTypingStatus(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      return Map<String, bool>.from(data?['typing'] ?? {});
    });
  }

  /// Delete a message
  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  /// Search messages
  Future<List<ChatMessage>> searchMessages(String conversationId, String query) async {
    // Note: Firestore doesn't support full-text search natively
    // For production, consider using Algolia or similar
    final snapshot = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(500)
        .get();

    return snapshot.docs
        .map((doc) => ChatMessage.fromFirestore(doc))
        .where((msg) => msg.text.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

/// Chat message model
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String? imageUrl;
  final DateTime timestamp;
  final bool read;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.imageUrl,
    required this.timestamp,
    required this.read,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
    );
  }

  bool get isImage => imageUrl != null && imageUrl!.isNotEmpty;
}

/// Conversation model
class Conversation {
  final String id;
  final List<String> participantIds;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderId;
  final Map<String, int> unreadCount;

  Conversation({
    required this.id,
    required this.participantIds,
    this.lastMessage,
    this.lastMessageAt,
    this.lastSenderId,
    required this.unreadCount,
  });

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      lastMessage: data['lastMessage'],
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      lastSenderId: data['lastSenderId'],
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
    );
  }

  int getUnreadCount(String userId) => unreadCount[userId] ?? 0;

  String getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere((id) => id != currentUserId, orElse: () => '');
  }
}
