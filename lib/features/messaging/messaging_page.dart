import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/chat_service.dart';
import '../../state/app_state.dart';
import 'chat_conversation_page.dart';

class MessagingPage extends StatefulWidget {
  const MessagingPage({super.key});

  @override
  State<MessagingPage> createState() => _MessagingPageState();
}

class _MessagingPageState extends State<MessagingPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentUserId = appState.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          if (_searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Searching for: "$_searchQuery"'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _searchQuery = ''),
                  ),
                ],
              ),
            ),

          // Conversations list
          Expanded(
            child: StreamBuilder<List<Conversation>>(
              stream: _chatService.getConversations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No conversations yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start chatting with your clients or contractors',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var conversations = snapshot.data!;

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  conversations = conversations.where((conv) {
                    // Note: In production, you'd want to fetch user names
                    // and search through them. For now, searching by message content
                    return conv.lastMessage
                            ?.toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ??
                        false;
                  }).toList();
                }

                return ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    final otherUserId = conversation.participantIds
                        .firstWhere((id) => id != currentUserId);
                    final unreadCount =
                        conversation.unreadCount[currentUserId] ?? 0;

                    return _ConversationTile(
                      conversation: conversation,
                      otherUserId: otherUserId,
                      unreadCount: unreadCount,
                      onTap: () => _openConversation(otherUserId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewMessageDialog,
        child: const Icon(Icons.message),
      ),
    );
  }

  void _openConversation(String otherUserId) async {
    // In a real app, you'd fetch the user's name from Firestore
    // For now, using a placeholder
    final userName = 'User $otherUserId';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatConversationPage(
          otherUserId: otherUserId,
          otherUserName: userName,
        ),
      ),
    );
  }

  void _showSearchDialog() async {
    final query = await showDialog<String>(
      context: context,
      builder: (context) {
        String searchText = '';
        return AlertDialog(
          title: const Text('Search Conversations'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search messages...',
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
      setState(() => _searchQuery = query);
    }
  }

  void _showNewMessageDialog() async {
    // In a real app, you'd show a list of users to start a conversation with
    // For now, showing a text input for user ID
    final userId = await showDialog<String>(
      context: context,
      builder: (context) {
        String userIdText = '';
        return AlertDialog(
          title: const Text('New Message'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter user ID...',
              prefixIcon: Icon(Icons.person),
            ),
            onChanged: (value) => userIdText = value,
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, userIdText),
              child: const Text('Start Chat'),
            ),
          ],
        );
      },
    );

    if (userId != null && userId.isNotEmpty) {
      _openConversation(userId);
    }
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final String otherUserId;
  final int unreadCount;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.otherUserId,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lastMessageTime = conversation.lastMessageAt;
    final timeString = _formatTime(lastMessageTime);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: Text(
          otherUserId.substring(0, 1).toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              'User $otherUserId', // In production, fetch real name
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            timeString,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conversation.lastMessage ?? 'No messages',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
              ),
            ),
          ),
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';

    return '${timestamp.month}/${timestamp.day}';
  }
}
