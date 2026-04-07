import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/auth_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// LOGIN: Agora simplificado para usar o E-mail Real diretamente.
  Future<UserCredential> loginComEmail(String email, String senha) async {
    return await _auth.signInWithEmailAndPassword(
      email: email, 
      password: senha,
    );
  }

  /// CRIAÇÃO DE USUÁRIOS SEM DESLOGAR (A lógica principal)
  /// Esta função permite que o SuperAdmin crie Admins, ou que Admins criem Técnicos,
  /// mantendo a sessão atual ativa.
  Future<void> cadastrarNovoUsuario({
    required String nome,
    required String email,
    required String senha,
    required String role, // 'admin' ou 'user'
    required String companyId,
    String? cpf, // CPF agora é opcional ou apenas informativo
  }) async {
    // 1. Criamos um nome único para a instância temporária para evitar conflitos
    String tempAppName = 'tempApp-${DateTime.now().millisecondsSinceEpoch}';

    try {
      // 2. Inicializa uma instância secundária do Firebase
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: tempAppName,
        options: Firebase.app().options,
      );

      // 3. Obtém o FirebaseAuth vinculado APENAS a essa instância secundária
      FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // 4. Cria o usuário no Authentication (sem afetar o _auth principal)
      UserCredential credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final String uid = credential.user!.uid;

      // 5. Salva os dados no Firestore usando a instância principal
      // (O SuperAdmin/Admin atual tem as permissões de escrita)
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': nome,
        'email': email,
        'cpf': cpf?.replaceAll(RegExp(r'[^0-9]'), '') ?? '',
        'role': role,
        'companyId': companyId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 6. Encerra e deleta a instância secundária para limpar a memória e a sessão temporária
      await secondaryApp.delete();

    } on FirebaseAuthException catch (e) {
      print("Erro de autenticação: ${e.code}");
      rethrow;
    } catch (e) {
      print("Erro ao cadastrar usuário: $e");
      rethrow;
    }
  }

  /// RECUPERAÇÃO DE SENHA
  /// Como o login é o e-mail real, o link cai direto na caixa de entrada do usuário.
  Future<void> recuperarSenha(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// BUSCA DE PERFIL
  Future<UserModel?> getPerfilUsuario(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  /// LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}