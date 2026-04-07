import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/auth_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _formatCpfToEmail(String cpf) {
    final cleanCpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    return '$cleanCpf@hectaria.com.br';
  }
  Future<UserCredential> loginComCpf(String cpf, String senha) async {
    final email = _formatCpfToEmail(cpf);
    return await _auth.signInWithEmailAndPassword(email: email, password: senha);
  }

  Future<UserModel?> getPerfilUsuario(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }
  
  Future<void> logout() async {
    await _auth.signOut();
  }
}