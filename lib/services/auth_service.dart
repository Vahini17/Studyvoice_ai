import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_voice_ai/models/user_model.dart';

class AuthService {
  final FirebaseAuth? _auth;

  bool _useLocalFallback = true;
  UserModel? _localUser;

  final StreamController<UserModel?> _userStreamController =
      StreamController<UserModel?>.broadcast();

  AuthService() : _auth = _safeInitFirebaseAuth() {
    _useLocalFallback = (_auth == null);
    _initializeUserSession();
  }

  static FirebaseAuth? _safeInitFirebaseAuth() {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint('Firebase Auth not initialized, falling back to local: $e');
      return null;
    }
  }

  Stream<UserModel?> get onAuthStateChanged => _userStreamController.stream;

  Future<void> _initializeUserSession() async {
    if (_useLocalFallback) {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('local_user_session');
      if (userJson != null) {
        try {
          _localUser = UserModel.fromJson(userJson);
          _userStreamController.add(_localUser);
        } catch (_) {
          _localUser = null;
          _userStreamController.add(null);
        }
      } else {
        _userStreamController.add(null);
      }
    } else {
      _auth!.authStateChanges().listen((User? firebaseUser) {
        if (firebaseUser != null) {
          _userStreamController.add(UserModel(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            displayName: firebaseUser.displayName ?? 'Student',
            photoUrl: firebaseUser.photoURL ?? '',
          ));
        } else {
          _userStreamController.add(null);
        }
      });
    }
  }

  Future<UserModel?> signInWithEmail(String email, String password,
      {bool rememberMe = false}) async {
    if (_useLocalFallback) {
      await Future.delayed(const Duration(seconds: 1));
      final prefs = await SharedPreferences.getInstance();
      final storedPassword = prefs.getString('local_user_pw_$email');

      if (storedPassword == null) {
        throw Exception('User does not exist. Please Sign Up first!');
      }
      if (storedPassword != password) {
        throw Exception('Incorrect password. Please try again.');
      }

      final storedUserJson = prefs.getString('local_user_data_$email');
      if (storedUserJson != null) {
        _localUser = UserModel.fromJson(storedUserJson);
      } else {
        _localUser = UserModel(
          uid: 'local_uid_${email.hashCode}',
          email: email,
          displayName: email.split('@')[0].toUpperCase(),
          photoUrl: '',
        );
      }

      if (rememberMe) {
        await prefs.setString('local_user_session', _localUser!.toJson());
      }
      _userStreamController.add(_localUser);
      return _localUser;
    } else {
      try {
        final credential = await _auth!
            .signInWithEmailAndPassword(email: email, password: password);
        if (credential.user != null) {
          final user = UserModel(
            uid: credential.user!.uid,
            email: credential.user!.email ?? '',
            displayName: credential.user!.displayName ?? 'Student',
            photoUrl: credential.user!.photoURL ?? '',
          );
          _userStreamController.add(user);
          return user;
        }
        throw Exception('Sign in failed. Please try again.');
      } on FirebaseAuthException catch (e) {
        throw Exception(e.code);
      }
    }
  }

  Future<UserModel?> signUpWithEmail(
      String displayName, String email, String password) async {
    if (_useLocalFallback) {
      await Future.delayed(const Duration(seconds: 1));
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('local_user_pw_$email') != null) {
        throw Exception('Email already registered. Please Login instead!');
      }

      await prefs.setString('local_user_pw_$email', password);
      _localUser = UserModel(
        uid: 'local_uid_${email.hashCode}',
        email: email,
        displayName: displayName,
        photoUrl: '',
      );
      await prefs.setString('local_user_data_$email', _localUser!.toJson());
      await prefs.setString('local_user_session', _localUser!.toJson());
      _userStreamController.add(_localUser);
      return _localUser;
    } else {
      final credential = await _auth!
          .createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        return UserModel(
          uid: credential.user!.uid,
          email: credential.user!.email ?? '',
          displayName: displayName,
          photoUrl: '',
        );
      }
      return null;
    }
  }

  /// Google Sign-In: in local fallback mode returns a simulated Google user.
  /// When Firebase is active, it uses google_sign_in v7 API.
  Future<UserModel?> signInWithGoogle() async {
    if (_useLocalFallback) {
      await Future.delayed(const Duration(milliseconds: 800));
      _localUser = UserModel(
        uid: 'google_local_uid_987654',
        email: 'student.google@gmail.com',
        displayName: 'Google Student',
        photoUrl: '',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_user_session', _localUser!.toJson());
      _userStreamController.add(_localUser);
      return _localUser;
    } else {
      // With Firebase active, use signInWithProvider which is the current
      // supported API in firebase_auth 6.x / google_sign_in 7.x
      try {
        final googleProvider = GoogleAuthProvider();
        final userCredential = await _auth!.signInWithProvider(googleProvider);
        if (userCredential.user != null) {
          return UserModel(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            displayName: userCredential.user!.displayName ?? 'Student',
            photoUrl: userCredential.user!.photoURL ?? '',
          );
        }
      } catch (e) {
        debugPrint('Google sign-in failed: $e');
      }
      return null;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (_useLocalFallback) {
      await Future.delayed(const Duration(milliseconds: 500));
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('local_user_pw_$email') == null) {
        throw Exception('Email not registered on this device.');
      }
      return;
    } else {
      await _auth!.sendPasswordResetEmail(email: email);
    }
  }

  Future<void> signOut() async {
    if (_useLocalFallback) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('local_user_session');
      _localUser = null;
      _userStreamController.add(null);
    } else {
      await _auth!.signOut();
    }
  }

  UserModel? get currentUser {
    if (_useLocalFallback) {
      return _localUser;
    } else {
      final firebaseUser = _auth!.currentUser;
      if (firebaseUser != null) {
        return UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? 'Student',
          photoUrl: firebaseUser.photoURL ?? '',
        );
      }
      return null;
    }
  }
}
