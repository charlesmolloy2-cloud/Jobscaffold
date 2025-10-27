import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../state/app_state.dart';

class ChatConversationPage extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatConversationPage({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();
  
  String? _conversationId;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeConversation();
  }

  Future<void> _initializeConversation() async {
    final appState = context.read<AppState>();
    final currentUserId = appState.currentUser?.id ?? '';
    
    final conversationId = await _chatService.getOrCreateConversation(
      currentUserId,
      widget.otherUserId,
    );
    setState(() {
      _conversationId = conversationId;
    });
    // Mark messages as read when viewing conversation
    _chatService.markAsRead(_conversationId!);
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
  // final appState = context.read<AppState>();
  // currentUserId not needed here
    
    final text = _messageController.text.trim();
    _messageController.clear();
    
    // Stop typing indicator
    _chatService.setTyping(_conversationId!, false);
    setState(() => _isTyping = false);
    
    await _chatService.sendMessage(
      conversationId: _conversationId!,
      text: text,
    );
    
    _scrollToBottom();
  }

  void _sendImage() async {
    final appState = context.read<AppState>();
    final currentUserId = appState.currentUser?.id ?? '';
    
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading image...')),
      );
    }

    // Upload image to storage
    final bytes = await image.readAsBytes();
    // Use PlatformFile for uploadFile
    final platformFile = PlatformFile(
      name: image.name,
      size: bytes.length,
      bytes: bytes,
      path: image.path,
    );
    final fileId = await _storageService.uploadFile(
      file: platformFile,
      userId: currentUserId,
      projectId: 'chat',
    );
    // Fetch file metadata to get downloadUrl
    final fileDoc = await FirebaseFirestore.instance.collection('files').doc(fileId).get();
    final fileData = fileDoc.data();
    final downloadUrl = fileData != null ? fileData['downloadUrl'] as String? : null;
    // Send message with image URL (text required)
    await _chatService.sendMessage(
      conversationId: _conversationId!,
      text: '',
      imageUrl: downloadUrl,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
    
    _scrollToBottom();
  }

  void _onTypingChanged(String text) {
    final isTyping = text.isNotEmpty;
    
    if (isTyping != _isTyping) {
      setState(() => _isTyping = isTyping);
      _chatService.setTyping(_conversationId!, isTyping);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    
    // Stop typing indicator on exit
    if (_conversationId != null) {
      _chatService.setTyping(_conversationId!, false);
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_conversationId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.otherUserName),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final appState = context.watch<AppState>();
    final currentUserId = appState.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName),
            StreamBuilder<Map<String, bool>>(
              stream: _chatService.getTypingStatus(_conversationId!),
              builder: (context, snapshot) {
                final isTyping = snapshot.data?[widget.otherUserId] ?? false;
                if (isTyping) {
                  return const Text(
                    'typing...',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(_conversationId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a message to start the conversation',
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!;
                
                // Mark messages as read when viewing
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _chatService.markAsRead(_conversationId!);
                });

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Show newest at bottom
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    final showTimestamp = index == messages.length - 1 ||
                        messages[index + 1].timestamp.difference(message.timestamp).inMinutes > 5;

                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                      showTimestamp: showTimestamp,
                      onDelete: () => _deleteMessage(message.id),
                    );
                  },
                );
              },
            ),
          ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: _sendImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: _onTypingChanged,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(String messageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _chatService.deleteMessage(_conversationId!, messageId);
    }
  }

  void _showSearchDialog() async {
    final query = await showDialog<String>(
      context: context,
      builder: (context) {
        String searchText = '';
        return AlertDialog(
          title: const Text('Search Messages'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter search term...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => searchText = value,
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, searchText),
              child: const Text('Search'),
            ),
          ],
        );
      },
    );

    if (query != null && query.isNotEmpty) {
      final results = await _chatService.searchMessages(_conversationId!, query);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Results for "$query"'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final message = results[index];
                  return ListTile(
                    title: Text(message.text),
                    subtitle: Text(
                      _formatTimestamp(message.timestamp),
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showTimestamp;
  final VoidCallback onDelete;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showTimestamp,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (isMe) const Spacer(flex: 2),
              Flexible(
                flex: 8,
                child: GestureDetector(
                  onLongPress: isMe ? onDelete : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Theme.of(context).primaryColor : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.imageUrl != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              message.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image, size: 48);
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          message.text,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isMe) const Spacer(flex: 2),
            ],
          ),
          if (showTimestamp)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: isMe ? 0 : 12,
                right: isMe ? 12 : 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.read ? Icons.done_all : Icons.done,
                      size: 14,
                      color: message.read ? Colors.blue : Colors.grey[600],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
