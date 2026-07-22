import 'package:flutter/material.dart';
import 'package:study_voice_ai/models/user_model.dart';
import 'package:study_voice_ai/services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthViewModel({required AuthService authService}) : _authService = authService {
    _authService.onAuthStateChanged.listen((UserModel? updatedUser) {
      _user = updatedUser;
      _errorMessage = null;
      notifyListeners();
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password, bool rememberMe) async {
    _setLoading(true);
    _setError(null);
    try {
      final loggedInUser = await _authService.signInWithEmail(email, password, rememberMe: rememberMe);
      _user = loggedInUser;
      _setLoading(false);
      return _user != null;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('user-not-found') || msg.contains('does not exist')) {
        _setError('No account found with this email. Please sign up first.');
      } else if (msg.contains('wrong-password') || msg.contains('Incorrect password')) {
        _setError('Incorrect password. Please try again.');
      } else if (msg.contains('invalid-email')) {
        _setError('Invalid email address format.');
      } else if (msg.contains('too-many-requests')) {
        _setError('Too many failed attempts. Please try again later.');
      } else if (msg.contains('network-request-failed')) {
        _setError('No internet connection. Please check your network.');
      } else {
        _setError(msg.replaceAll("Exception: ", "").replaceAll("[firebase_auth/", "").replaceAll("]", ""));
      }
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp(String displayName, String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final createdUser = await _authService.signUpWithEmail(displayName, email, password);
      _user = createdUser;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll("Exception: ", ""));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _setError(null);
    try {
      final googleUser = await _authService.signInWithGoogle();
      _user = googleUser;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll("Exception: ", ""));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll("Exception: ", ""));
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    await _authService.signOut();
    _user = null;
    _setLoading(false);
  }

  void clearErrors() {
    _setError(null);
  }
}
