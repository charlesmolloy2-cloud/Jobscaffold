import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationBell extends StatelessWidget {
  final double size;
  final Color? color;
  const NotificationBell({super.key, this.size = 24, this.color});

  Stream<int> _unreadCount(String uid) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return IconButton(
        tooltip: 'Notifications',
        icon: Icon(Icons.notifications_none, size: size, color: color),
        onPressed: null,
      );
    }
    return StreamBuilder<int>(
      stream: _unreadCount(user.uid),
      builder: (context, snap) {
  final count = snap.data ?? 0;
  final hasUnread = count > 0;
  // Align with bottom-nav badge: compact to 9+
  final display = count > 9 ? '9+' : '$count';
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notifications',
              icon: Icon(hasUnread ? Icons.notifications_active : Icons.notifications_none, size: size, color: color),
              onPressed: () => Navigator.of(context).pushNamed('/notifications'),
            ),
            if (hasUnread)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    display,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
