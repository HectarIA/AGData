import 'package:flutter/foundation.dart';
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
}