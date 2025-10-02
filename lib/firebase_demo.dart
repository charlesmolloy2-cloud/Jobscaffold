import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseDemoPage extends StatefulWidget {
  const FirebaseDemoPage({Key? key}) : super(key: key);

  @override
  State<FirebaseDemoPage> createState() => _FirebaseDemoPageState();
}

class _FirebaseDemoPageState extends State<FirebaseDemoPage> {
  String _status = '';
  String? _downloadUrl;

  // Example: Sign in anonymously
  Future<void> _signInAnon() async {
    final user = await FirebaseAuth.instance.signInAnonymously();
    setState(() => _status = 'Signed in: ${user.user?.uid}');
  }

  // Example: Add data to Firestore
  Future<void> _addToFirestore() async {
    await FirebaseFirestore.instance.collection('demo').add({'timestamp': DateTime.now().toIso8601String()});
    setState(() => _status = 'Added to Firestore!');
  }

  // Example: Upload a string as a file to Storage
  Future<void> _uploadToStorage() async {
    final ref = FirebaseStorage.instance.ref('demo.txt');
    await ref.putString('Hello from Flutter!');
    final url = await ref.getDownloadURL();
    setState(() {
      _status = 'Uploaded to Storage!';
      _downloadUrl = url;
    });
  }

  // Example: Get FCM token
  Future<void> _getFcmToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    setState(() => _status = 'FCM Token: $token');
  }

  // Example: Log an analytics event
  Future<void> _logAnalytics() async {
    await FirebaseAnalytics.instance.logEvent(name: 'demo_event', parameters: {'foo': 'bar'});
    setState(() => _status = 'Analytics event logged!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Demo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _signInAnon,
              child: const Text('Sign in Anonymously'),
            ),
            ElevatedButton(
              onPressed: _addToFirestore,
              child: const Text('Add to Firestore'),
            ),
            ElevatedButton(
              onPressed: _uploadToStorage,
              child: const Text('Upload to Storage'),
            ),
            ElevatedButton(
              onPressed: _getFcmToken,
              child: const Text('Get FCM Token'),
            ),
            ElevatedButton(
              onPressed: _logAnalytics,
              child: const Text('Log Analytics Event'),
            ),
            const SizedBox(height: 24),
            Text(_status, style: const TextStyle(fontSize: 16)),
            if (_downloadUrl != null) ...[
              const SizedBox(height: 8),
              SelectableText('Download URL: $_downloadUrl'),
            ],
          ],
        ),
      ),
    );
  }
}
