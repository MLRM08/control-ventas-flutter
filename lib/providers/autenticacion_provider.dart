import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AutenticacionProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _usuario;

  User? get usuario => _usuario;

  AutenticacionProvider() {
    _auth.authStateChanges().listen((User? user) {
      _usuario = user;
      notifyListeners();
    });
  }

  Future registrar(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future iniciarSesion(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future cerrarSesion() async {
    await _auth.signOut();
  }
}
