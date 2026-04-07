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

  /// CADASTRO DE NOVO USUÁRIO (Com suporte a Telefone)
  Future<void> cadastrarNovoUsuario({
    required String nome,
    required String email,
    required String senha,
    required String role,
    required String companyId,
    String? cpf,
    String? phone, // 📱 Novo parâmetro adicionado
  }) async {
    // Criamos um nome único para a instância temporária do Firebase
    String tempAppName = 'tempApp-${DateTime.now().millisecondsSinceEpoch}';

    try {
      // Inicializa app secundário para não deslogar o Admin atual
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: tempAppName,
        options: Firebase.app().options,
      );

      FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      
      // Cria o usuário no Firebase Auth
      UserCredential credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final String uid = credential.user!.uid;

      // Salva os dados estendidos no Firestore
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': nome,
        'email': email,
        'phone': phone ?? '', // 📱 Salvando o telefone no banco
        'cpf': cpf?.replaceAll(RegExp(r'[^0-9]'), '') ?? '',
        'role': role,
        'companyId': companyId,
        'needsPasswordChange': true, // Força a troca no primeiro login
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Limpa a instância temporária
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