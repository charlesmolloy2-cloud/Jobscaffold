import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/tasks/kanban_board_page.dart';
import '../../features/dashboard/project_dashboard_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> _userNotifications(String uid) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();
  }

  Future<void> _markAsRead(DocumentSnapshot<Map<String, dynamic>> doc) async {
    await doc.reference.update({'read': true});
  }

  Future<void> _delete(DocumentSnapshot<Map<String, dynamic>> doc) async {
    await doc.reference.delete();
  }

  void _navigateFor(Map<String, dynamic> n) {
    final type = (n['type'] ?? '').toString();
    final data = (n['data'] as Map<String, dynamic>?) ?? const {};
    final projectId = data['projectId'] as String?;

    if (type.startsWith('task')) {
      if (projectId != null && projectId.isNotEmpty) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => KanbanBoardPage(projectId: projectId),
        ));
      }
      return;
    }
    if (type == 'check_in') {
      if (projectId != null && projectId.isNotEmpty) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ProjectDashboardPage(projectId: projectId, projectName: ''),
        ));
      }
      return;
    }
    if (type == 'contract_completed') {
      // If we had a contract page, navigate there; fallback noop
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (user != null)
            TextButton(
              onPressed: () async {
                final snap = await _db
                    .collection('notifications')
                    .where('userId', isEqualTo: user.uid)
                    .where('read', isEqualTo: false)
                    .limit(200)
                    .get();
                for (final d in snap.docs) {
                  await d.reference.update({'read': true});
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked all as read')));
                }
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Sign in to view notifications'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _userNotifications(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No notifications yet'));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final n = d.data();
                    final title = (n['title'] as String?) ?? 'Notification';
                    final body = (n['body'] as String?) ?? '';
                    final ts = (n['createdAt'] as Timestamp?);
                    final read = (n['read'] as bool?) ?? false;
                    final time = ts?.toDate();
                    return Dismissible(
                      key: ValueKey(d.id),
                      background: Container(color: Colors.green, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 16), child: const Icon(Icons.mark_email_read, color: Colors.white)),
                      secondaryBackground: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          await _markAsRead(d);
                          return false; // keep item
                        } else {
                          await _delete(d);
                          return true; // remove item
                        }
                      },
                      child: ListTile(
                        leading: Icon(read ? Icons.notifications_none : Icons.notifications_active),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (body.isNotEmpty) Text(body),
                            if (time != null) Text(_ago(time), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                        onTap: () {
                          _navigateFor(n);
                          _markAsRead(d);
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

String _ago(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'just now';
}
