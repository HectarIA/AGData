import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/auth_model.dart';

class SessionController extends ChangeNotifier {
  UserModel? _usuario;

  UserModel? get usuario => _usuario;
  String? get companyId => _usuario?.companyId;
  bool get estaLogado => _usuario != null;

  void setUsuario(UserModel usuario) {
    _usuario = usuario;
    notifyListeners(); 
  }

  void limparSessao() {
    _usuario = null;
    notifyListeners();
  }

  /// Busca os dados do usuário no Firestore para garantir que a sessão 
  /// local contenha todas as permissões e dados da empresa.
  Future<void> inicializarUsuario() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      
      if (firebaseUser != null) {
        // Busca na coleção 'users' usando o UID do Firebase Auth
        final doc = await FirebaseFirestore.instance
            .collection('users') 
            .doc(firebaseUser.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          // Utiliza o factory fromMap que você definiu no UserModel
          _usuario = UserModel.fromMap(doc.data()!);
          debugPrint("Sessão inicializada com sucesso: ${_usuario?.name}");
        } else {
          _usuario = null;
          debugPrint("Atenção: Usuário logado no Auth, mas documento não encontrado no Firestore.");
        }
      } else {
        _usuario = null;
      }
    } catch (e) {
      _usuario = null;
      debugPrint("Erro crítico ao carregar dados da sessão: $e");
      rethrow; 
    } finally {
      notifyListeners();
    }
  }
}