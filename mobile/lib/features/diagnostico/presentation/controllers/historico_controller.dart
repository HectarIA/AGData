import 'package:flutter/material.dart';
import '../../domain/entities/leitura.dart';
import '../../domain/usecases/obter_leituras_usecase.dart';

class HistoricoController extends ChangeNotifier {
  final ObterTodasLeiturasUseCase _useCase;

  HistoricoController(this._useCase);

  List<Leitura> _todasLeituras = [];
  bool _isLoading = true;

  List<Leitura> get todasLeituras => _todasLeituras;
  bool get isLoading => _isLoading;

  Future<void> carregarLeituras() async {
    _isLoading = true;
    notifyListeners(); // Avisa a tela para mostrar o loading

    try {
      _todasLeituras = await _useCase.execute();
      _todasLeituras = _todasLeituras.reversed.toList(); // Ordena
    } catch (e) {
      debugPrint("Erro ao carregar leituras: $e");
    } finally {
      _isLoading = false;
      notifyListeners(); // Avisa a tela que os dados chegaram
    }
  }
}