import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();

  User? _user;
  String _role = 'user';
  bool _isLoading = false;

  User? get user => _user;
  String get role => _role;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _role == 'admin';


  Future<void> initUser() async {
  _user = _service.currentUser;

  if (_user != null) {
    await _service.ensureUserDocument(_user!);
    _role = await _service.getUserRole(_user!.uid);
  } else {
    _role = 'user';
  }

  notifyListeners();
}

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _service.signIn(email, password);

      if (user != null) {
           await _service.ensureUserDocument(user);
           _user = user;
           _role = await _service.getUserRole(user.uid);
          return true;
      }

      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.signOut();
      _user = null;
      _role = 'user';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setUser(User? user) async {
    _user = user;

    if (user != null) {
      _role = await _service.getUserRole(user.uid);
    } else {
      _role = 'user';
    }

    notifyListeners();
  }
}