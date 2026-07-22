import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage? _storage;
  bool _useLocalFallback = true;

  StorageService() : _storage = _safeInitStorage() {
    _useLocalFallback = (_storage == null);
  }

  static FirebaseStorage? _safeInitStorage() {
    try {
      return FirebaseStorage.instance;
    } catch (e) {
      debugPrint("Firebase Storage not initialized, falling back to local file path mapping: $e");
      return null;
    }
  }

  Future<String> uploadPdf(String userId, File file, String fileName) async {
    if (_useLocalFallback) {
      await Future.delayed(const Duration(milliseconds: 600)); // Simulate upload latency
      // Return the local file path as the reference url
      return file.path;
    } else {
      try {
        final ref = _storage!
            .ref()
            .child('users')
            .child(userId)
            .child('pdfs')
            .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

        final uploadTask = await ref.putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        return downloadUrl;
      } catch (e) {
        debugPrint('Firebase Storage upload failed, falling back to local path: $e');
        return file.path; // Always return something usable
      }
    }
  }
}
