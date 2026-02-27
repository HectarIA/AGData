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
      _interpreter = await Interpreter.fromAsset('assets/models/modelo_soja_2.tflite');
      
      final labelString = await rootBundle.loadString('assets/labels_v2.txt');
      _labels = labelString.split('\n').where((s) => s.isNotEmpty).toList();
      
      debugPrint('✅ Cérebro da IA (HectarIA) carregado com sucesso!');
      debugPrint('Categorias detectadas: $_labels');
    } catch (e) {
      debugPrint('❌ Erro crítico ao carregar o modelo TFLite: $e');
    }
  }

  Future<String> predict(File imageFile) async {
    if (_interpreter == null || _labels == null) {
      await loadModel();
      if (_interpreter == null) return "Erro: IA não carregada";
    }

    var imageBytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) return "Erro ao decodificar imagem";

    img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224);
    
    var input = [
      List.generate(224, (y) {
        return List.generate(224, (x) {
          var pixel = resizedImage.getPixel(x, y);
          return [
            pixel.r.toDouble() / 255.0, 
            pixel.g.toDouble() / 255.0, 
            pixel.b.toDouble() / 255.0
          ];
        });
      })
    ];

    var outputBuffer = List.filled(1 * _labels!.length, 0.0).reshape([1, _labels!.length]);

    _interpreter!.run(input, outputBuffer);

    List<double> probabilities = List<double>.from(outputBuffer[0]);
    int highestIndex = 0;
    double maxConfidence = -1.0;

    for (int i = 0; i < probabilities.length; i++) {
      if (probabilities[i] > maxConfidence) {
        maxConfidence = probabilities[i];
        highestIndex = i;
      }
    }

    return _labels![highestIndex];
  }
  
  void close() {
    _interpreter?.close();
  }
}