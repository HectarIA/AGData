import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../models/auth_model.dart';
import '../../presentation/controller/session_controller.dart';
import 'package:mobile/core/di/injection_container.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Isar _isar = sl<Isar>(); 

  /// Realiza o login retornando o UserModel. 
  /// Se houver internet, autentica no Firebase. Se não, busca no Isar.
  Future<UserModel?> loginComEmail(String email, String senha) async {
    try {
      // 1. Tenta autenticação online
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(), 
        password: senha
      );
      
      // 2. Busca o perfil completo no Firestore
      final userModel = await getPerfilUsuario(credential.user!.uid);
      
      if (userModel != null) {
        // 3. Sucesso: Cache local no Isar para permitir logins offline futuros
        await _isar.writeTxn(() async {
          await _isar.userModels.put(userModel);
        });
        
        sl<SessionController>().setUsuario(userModel);
        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      // 📶 TRATAMENTO PARA LOGIN OFFLINE
      // Verificamos se é erro de rede ou falha de canal (comum em emuladores/offline)
      if (e.code == 'network-request-failed' || e.code == 'channel-error') {
        final usuarioLocal = await _isar.userModels.filter().emailEqualTo(email).findFirst();
        
        if (usuarioLocal != null) {
          // Concede acesso com base no banco local
          sl<SessionController>().setUsuario(usuarioLocal);
          return usuarioLocal; 
        }
      }
      // Se não for erro de rede ou não achar localmente, repassa o erro (ex: senha errada)
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> recuperarUsuarioLogado() async {
    final User? firebaseUser = _auth.currentUser;
    
    if (firebaseUser != null) {
      try {
        final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists && doc.data() != null) {
          final userModel = UserModel.fromMap(doc.data()!);
          
          await _isar.writeTxn(() => _isar.userModels.put(userModel));
          
          sl<SessionController>().setUsuario(userModel);
          return userModel;
        }
      } catch (e) {
        debugPrint("Erro Firestore, tentando Isar: $e");
      }
    }

    final usuarioLocal = await _isar.userModels.where().findFirst();
    if (usuarioLocal != null) {
      sl<SessionController>().setUsuario(usuarioLocal);
      return usuarioLocal;
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
      
      final local = await _isar.userModels.filter().uidEqualTo(user.uid).findFirst();
      if (local != null) {
        local.needsPasswordChange = false;
        await _isar.writeTxn(() => _isar.userModels.put(local));
      }
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
      
      final userData = {
        'uid': uid,
        'name': nome,
        'email': email,
        'phone': phone ?? '',
        'cpf': cpf?.replaceAll(RegExp(r'[^0-9]'), '') ?? '',
        'role': role,
        'companyId': companyId,
        'needsPasswordChange': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(uid).set(userData);
      await secondaryApp.delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> recuperarSenha(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserModel?> getPerfilUsuario(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final user = UserModel.fromMap(doc.data()!);
        return user;
      }
    } catch (e) {
      return await _isar.userModels.filter().uidEqualTo(uid).findFirst();
    }
    return null;
  }

  Future<void> logout() async {
    try {
      sl<SessionController>().limparSessao();
      
      // Limpa os dados do usuário do Isar no logout para garantir privacidade
      await _isar.writeTxn(() => _isar.userModels.clear());
      
      await _auth.signOut();
    } catch (e) {
      debugPrint("Erro durante o logout: $e");
      rethrow;
    }
  }
}