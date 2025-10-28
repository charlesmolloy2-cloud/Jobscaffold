import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Displays a small red pill badge with a compact unread count (9+)
/// overlaid on the given child (typically a BottomNavigationBar icon).
class NotificationsBadge extends StatelessWidget {
  final Widget child;
  const NotificationsBadge({super.key, required this.child});

  Stream<int> _unreadCount(String uid) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  String _compactCount(int count) {
    if (count <= 0) return '';
    if (count > 9) return '9+';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return child;
    return StreamBuilder<int>(
      stream: _unreadCount(user.uid),
      builder: (context, snap) {
        final c = snap.data ?? 0;
        final label = _compactCount(c);
        if (label.isEmpty) return child;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
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
