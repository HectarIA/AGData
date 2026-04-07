import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/auth_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> loginComEmail(String email, String senha) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: senha);
  }

  /// ATUALIZAÇÃO DE SENHA (Para o primeiro acesso)
  Future<void> atualizarSenha(String novaSenha) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(novaSenha);
      // Após atualizar no Auth, removemos a flag no Firestore
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
        'cpf': cpf?.replaceAll(RegExp(r'[^0-9]'), '') ?? '',
        'role': role,
        'companyId': companyId,
        'needsPasswordChange': true, // Força a troca no primeiro login
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

  Future<void> logout() async {
    await _auth.signOut();
  }
}