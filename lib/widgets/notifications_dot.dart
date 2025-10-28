import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Small red dot indicator shown on top of a child icon
class NotificationsDot extends StatelessWidget {
  final Widget child;
  final Alignment alignment;
  const NotificationsDot({super.key, required this.child, this.alignment = Alignment.topRight});

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
    if (user == null) return child;
    return StreamBuilder<int>(
      stream: _unreadCount(user.uid),
      builder: (context, snap) {
        final hasUnread = (snap.data ?? 0) > 0;
        if (!hasUnread) return child;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
