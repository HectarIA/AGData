import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/auth_model.dart';
import '../../presentation/controller/session_controller.dart';
import 'package:mobile/core/di/injection_container.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> loginComEmail(String email, String senha) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: senha);
  }

  Future<UserModel?> recuperarUsuarioLogado() async {
    final User? firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      try {
        final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists && doc.data() != null) {
          final userModel = UserModel.fromMap(doc.data()!);
          sl<SessionController>().setUsuario(userModel);
          return userModel;
        }
      } catch (e) {
        debugPrint("Erro ao recuperar dados do Firestore: $e");
        return null;
      }
    }
    return null;
  }

  Future<void> atualizarSenha(String novaSenha) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(novaSenha);
      await _firestore.collection('users').doc(user.uid).update({
        'needsPasswordChange': false,
      });
    }
  }

  Future<void> cadastrarNovoUsuario({
    required String nome,
    required String email,
    required String senha,
    required String role,
    required String companyId,
    String? cpf,
    String? phone,
  }) async {
    String tempAppName = 'tempApp-${DateTime.now().millisecondsSinceEpoch}';
    try {
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: tempAppName,
        options: Firebase.app().options,
      );
      FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      UserCredential credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );
      final String uid = credential.user!.uid;
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': nome,
        'email': email,
        'phone': phone ?? '',
        'cpf': cpf?.replaceAll(RegExp(r'[^0-9]'), '') ?? '',
        'role': role,
        'companyId': companyId,
        'needsPasswordChange': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await secondaryApp.delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> recuperarSenha(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserModel?> getPerfilUsuario(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);
    return null;
  }

  /// Logout atualizado para garantir limpeza total
  Future<void> logout() async {
    try {
      // Limpa a sessão no controller primeiro para atualizar a UI imediatamente
      sl<SessionController>().limparSessao();
      // Desloga do Firebase
      await _auth.signOut();
    } catch (e) {
      debugPrint("Erro durante o logout: $e");
      rethrow;
    }
  }
}