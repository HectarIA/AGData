import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class Classifier {
  Interpreter? _interpreter;
  List<String>? _labels;

  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset('assets/models/modelo_soja_v11.tflite', options: options);
      
      final labelString = await rootBundle.loadString('assets/labels.txt');
      _labels = labelString.split('\n').where((s) => s.isNotEmpty).toList();
      
      debugPrint('✅ Cérebro da IA carregado! Input Shape: ${_interpreter!.getInputTensor(0).shape}');
      debugPrint('✅ Output Shape esperado: ${_interpreter!.getOutputTensor(0).shape}');
    } catch (e) {
      debugPrint('❌ Erro crítico ao carregar o modelo: $e');
    }
  }

  // Agora retorna um Mapa contendo a label e a confiança
  Future<Map<String, dynamic>> predict(File imageFile) async {
    if (_interpreter == null) await loadModel();
    if (_interpreter == null) {
      return {'label': 'Erro: IA não carregada', 'confidence': 0.0};
    }

    var imageBytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) {
      return {'label': 'Erro ao decodificar imagem', 'confidence': 0.0};
    }

    img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224);
    
    // Preparação do Input
    var input = List.generate(1, (b) {
      return List.generate(224, (y) {
        return List.generate(224, (x) {
          var pixel = resizedImage.getPixel(x, y);
          return [
            pixel.r.toDouble() / 255.0,
            pixel.g.toDouble() / 255.0,
            pixel.b.toDouble() / 255.0
          ];
        });
      });
    });

    var outputShape = _interpreter!.getOutputTensor(0).shape;
    var outputBuffer = List.filled(outputShape[0] * outputShape[1], 0.0).reshape(outputShape);

    try {
      debugPrint("⚙️ Executando inferência...");
      _interpreter!.run(input, outputBuffer);
      debugPrint("✅ Inferência executada.");
    } catch (e) {
      debugPrint("❌ ERRO NO INTERPRETER.RUN: $e");
      return {'label': 'Erro na execução da IA', 'confidence': 0.0};
    }

    // Processamento da saída
    List<double> probabilities = List<double>.from(outputBuffer[0]);
    int highestIndex = 0;
    double maxConfidence = -1.0;

    for (int i = 0; i < probabilities.length; i++) {
      if (probabilities[i] > maxConfidence) {
        maxConfidence = probabilities[i];
        highestIndex = i;
      }
    }

    if (highestIndex < _labels!.length) {
      return {
        'label': _labels![highestIndex],
        'confidence': maxConfidence,
      };
    } else {
      return {'label': 'Categoria não encontrada', 'confidence': 0.0};
    }
  }
  
  void close() {
    _interpreter?.close();
  }
}