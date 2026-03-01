import 'package:flutter/material.dart';
import '../../data/datasources/database_service.dart';
import '../../data/models/talhao_model.dart';

class SelecaoTalhaoController extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<TalhaoModel> talhoes = [];
  String? talhaoSelecionado;
  bool loading = true;

  SelecaoTalhaoController() {
    _carregarTalhoes();
  }

  Future<void> _carregarTalhoes() async {
    loading = true;
    notifyListeners();

    talhoes = await _databaseService.buscarTodosTalhoes();
    
    if (talhaoSelecionado == null && talhoes.isNotEmpty) {
      talhaoSelecionado = talhoes.first.nome;
    }
    
    loading = false;
    notifyListeners();
  }

  Future<void> salvarTalhao(String nome) async {
    final novoTalhao = TalhaoModel()..nome = nome;
    await _databaseService.guardarTalhao(novoTalhao);
    await _carregarTalhoes(); // Recarrega a lista após salvar
  }

  void selecionarTalhao(String nome) {
    talhaoSelecionado = nome;
    notifyListeners();
  }
}