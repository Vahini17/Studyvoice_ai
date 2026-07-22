import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_voice_ai/models/pdf_model.dart';
import 'package:study_voice_ai/models/bookmark_model.dart';
import 'package:study_voice_ai/models/note_model.dart';
import 'package:study_voice_ai/models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore? _firestore;
  bool _useLocalFallback = true;

  DatabaseService() : _firestore = _safeInitFirestore() {
    _useLocalFallback = (_firestore == null);
  }

  static FirebaseFirestore? _safeInitFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint("Firestore not initialized, falling back to local database caching: $e");
      return null;
    }
  }

  // --- PDF Operations ---
  Future<void> savePdf(PdfModel pdf) async {
    if (_useLocalFallback) {
      final prefs = await SharedPreferences.getInstance();
      final pdfsListJson = prefs.getStringList('local_pdfs_${pdf.userId}') ?? [];
      
      // Update if exists, else add
      final List<PdfModel> currentPdfs = pdfsListJson
          .map((item) => PdfModel.fromJson(item))
          .toList();
      
      final index = currentPdfs.indexWhere((p) => p.id == pdf.id);
      if (index >= 0) {
        currentPdfs[index] = pdf;
      } else {
        currentPdfs.add(pdf);
      }
      
      final updatedPdfsJson = currentPdfs.map((p) => p.toJson()).toList();
      await prefs.setStringList('local_pdfs_${pdf.userId}', updatedPdfsJson);
    } else {
      await _firestore!
          .collection('users')
          .doc(pdf.userId)
          .collection('pdfs')
          .doc(pdf.id)
          .set(pdf.toMap());
    }
  }

  Future<List<PdfModel>> getPdfs(String userId) async {
    if (_useLocalFallback) {
      final prefs = await SharedPreferences.getInstance();
      final pdfsListJson = prefs.getStringList('local_pdfs_$userId') ?? [];
      return pdfsListJson.map((item) => PdfModel.fromJson(item)).toList();
    } else {
      final snapshot = await _firestore!
          .collection('users')
          .doc(userId)
          .collection('pdfs')
          .orderBy('uploadTimestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => PdfModel.fromMap(doc.data())).toList();
    }
  }

  Future<void> deletePdf(String userId, String pdfId) async {
    if (_useLocalFallback) {
      final prefs = await SharedPreferences.getInstance();
      final pdfsListJson = prefs.getStringList('local_pdfs_$userId') ?? [];
      final List<PdfModel> currentPdfs = pdfsListJson
          .map((item) => PdfModel.fromJson(item))
          .toList();
      
      currentPdfs.removeWhere((p) => p.id == pdfId);
      final updatedPdfsJson = currentPdfs.map((p) => p.toJson()).toList();
      await prefs.setStringList('local_pdfs_$userId', updatedPdfsJson);
    } else {
      await _firestore!
          .collection('users')
          .doc(userId)
          .collection('pdfs')
          .doc(pdfId)
          .delete();
    }
  }

  // --- Bookmark Operations ---
  Future<void> saveBookmark(BookmarkModel bookmark) async {
    if (_useLocalFallback) {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList('local_bookmarks_${bookmark.pdfId}') ?? [];
      final List<BookmarkModel> currentBookmarks = bookmarksJson
          .map((item) => BookmarkModel.fromJson(item))
          .toList();

      final index = currentBookmarks.indexWhere((b) => b.id == bookmark.id);
      if (index >= 0) {
        currentBookmarks[index] = bookmark;
      } else {
        currentBookmarks.add(bookmark);
      }

      final updatedJson = currentBookmarks.map((b) => b.toJson()).toList();
      await prefs.setStringList('local_bookmarks_${bookmark.pdfId}', updatedJson);
    } else {
      await _firestore!
          .collection('pdfs')
          .doc(bookmark.pdfId)
          .collection('bookmarks')
          .doc(bookmark.id)
          .set(bookmark.toMap());
    }
  }

  Future<List<BookmarkModel>> getBookmarks(String pdfId) async {
    if (_useLocalFallback) {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList('local_bookmarks_$pdfId') ?? [];
      return bookmarksJson.map((item) => BookmarkModel.fromJson(item)).toList();
    } else {
      final snapshot = await _firestore!
          .collection('pdfs')
          .doc(pdfId)
          .collection('bookmarks')
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => BookmarkModel.fromMap(doc.data())).toList();
    }
  }

  Future<void> deleteBookmark(String pdfId, String bookmarkId) async {
    if (_useLocalFallback) {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList('local_bookmarks_$pdfId') ?? [];
      final List<BookmarkModel> currentBookmarks = bookmarksJson
          .map((item) => BookmarkModel.fromJson(item))
          .toList();

      currentBookmarks.removeWhere((b) => b.id == bookmarkId);
      final updatedJson = currentBookmarks.map((b) => b.toJson()).toList();
      await prefs.setStringList('local_bookmarks_$pdfId', updatedJson);
    } else {
      await _firestore!
          .collection('pdfs')
          .doc(pdfId)
          .collection('bookmarks')
          .doc(bookmarkId)
          .delete();
    }
  }

  // --- Note Operations ---
  Future<void> saveNote(NoteModel note) async {
    if (_useLocalFallback) {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList('local_notes_${note.pdfId}') ?? [];
      final List<NoteModel> currentNotes = notesJson
          .map((item) => NoteModel.fromJson(item))
          .toList();

      final index = currentNotes.indexWhere((n) => n.id == note.id);
      if (index >= 0) {
        currentNotes[index] = note;
      } else {
        currentNotes.add(note);
      }

      final updatedJson = currentNotes.map((n) => n.toJson()).toList();
      await prefs.setStringList('local_notes_${note.pdfId}', updatedJson);
    } else {
      await _firestore!
          .collection('pdfs')
          .doc(note.pdfId)
          .collection('notes')
          .doc(note.id)
          .set(note.toMap());
    }
  }

  Future<List<NoteModel>> getNotes(String pdfId) async {
    if (_useLocalFallback) {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList('local_notes_$pdfId') ?? [];
      return notesJson.map((item) => NoteModel.fromJson(item)).toList();
    } else {
      final snapshot = await _firestore!
          .collection('pdfs')
          .doc(pdfId)
          .collection('notes')
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => NoteModel.fromMap(doc.data())).toList();
    }
  }

  Future<void> deleteNote(String pdfId, String noteId) async {
    if (_useLocalFallback) {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList('local_notes_$pdfId') ?? [];
      final List<NoteModel> currentNotes = notesJson
          .map((item) => NoteModel.fromJson(item))
          .toList();

      currentNotes.removeWhere((n) => n.id == noteId);
      final updatedJson = currentNotes.map((n) => n.toJson()).toList();
      await prefs.setStringList('local_notes_$pdfId', updatedJson);
    } else {
      await _firestore!
          .collection('pdfs')
          .doc(pdfId)
          .collection('notes')
          .doc(noteId)
          .delete();
    }
  }

  // --- User Study Statistics & Profile Sync ---
  Future<void> saveUserStats(UserModel user) async {
    if (_useLocalFallback) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_user_data_${user.email}', user.toJson());
      await prefs.setString('local_user_session', user.toJson());
    } else {
      try {
        await _firestore!
            .collection('users')
            .doc(user.uid)
            .set(user.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint("Firestore saveUserStats failed (database might not be created): $e");
      }
    }
  }

  Future<UserModel?> getUserStats(String uid, String email) async {
    if (_useLocalFallback) {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('local_user_data_$email');
      if (userJson != null) {
        return UserModel.fromJson(userJson);
      }
      return null;
    } else {
      final doc = await _firestore!.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    }
  }
}
