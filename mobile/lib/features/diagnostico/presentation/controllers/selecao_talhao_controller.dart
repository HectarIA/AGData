import 'package:flutter/material.dart';
import '../../data/datasources/database_service.dart';
import '../../data/models/talhao_model.dart';

class SelecaoTalhaoController extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<TalhaoModel> talhoes = [];
  bool loading = true;

  /// Data da última leitura registrada em cada talhão (por nome).
  Map<String, DateTime> ultimaLeitura = {};

  /// Total de leituras por talhão (por nome).
  Map<String, int> totalLeituras = {};

  SelecaoTalhaoController() {
    _carregarTalhoes();
  }

  Future<void> _carregarTalhoes() async {
    loading = true;
    notifyListeners();

    talhoes = await _databaseService.buscarTodosTalhoes();
    final leituras = await _databaseService.buscarTodasLeituras();

    ultimaLeitura = {};
    totalLeituras = {};
    for (final l in leituras) {
      totalLeituras[l.talhao] = (totalLeituras[l.talhao] ?? 0) + 1;
      final atual = ultimaLeitura[l.talhao];
      if (atual == null || l.dataHora.isAfter(atual)) {
        ultimaLeitura[l.talhao] = l.dataHora;
      }
    }

    loading = false;
    notifyListeners();
  }

  /// Recarrega talhões e estatísticas (ex: ao voltar da tela de análise).
  Future<void> recarregar() => _carregarTalhoes();

  Future<void> salvarTalhao(String nome) async {
    final novoTalhao = TalhaoModel()..nome = nome;
    await _databaseService.guardarTalhao(novoTalhao);
    await _carregarTalhoes();
  }
}
