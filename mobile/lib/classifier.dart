import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:image/image.dart' as img; 
import 'package:tflite_flutter/tflite_flutter.dart';

class Classifier {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/modelo_soja_2.tflite');
      debugPrint('✅ Cérebro da IA (Modelo) carregado com sucesso!');
      

      var inputShape = _interpreter!.getInputTensor(0).shape;
      debugPrint("Formato esperado pela IA: $inputShape");
      
    } catch (e) {
      debugPrint('❌ Erro crítico ao carregar o modelo TFLite: $e');
      debugPrint('Verifique se o arquivo está na pasta assets e se o pubspec.yaml está configurado.');
    }
  }

  // Função principal que faz a previsão
  Future<List<double>> predict(File imageFile) async {
    if (_interpreter == null) {
      debugPrint("⚠️ Interpretador não estava pronto. Inicializando agora...");
      await loadModel();
      
      if (_interpreter == null) {
        debugPrint("⛔ Não foi possível realizar a previsão: Modelo não carregado.");
        return [];
      }
    }

    // 1. Ler a imagem do arquivo
    var imageBytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) {
      debugPrint("Erro ao decodificar a imagem.");
      return [];
    }

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

    // 4. Preparar o buffer de saída (onde a IA vai cuspir as probabilidades)
    var outputBuffer = List.filled(1 * 4, 0.0).reshape([1, 4]);

    // 5. Rodar a previsão (A mágica acontece aqui)
    _interpreter!.run(input, outputBuffer);

    // 6. Retornar a lista de probabilidades (ex: [0.1, 0.85, 0.05])
    List<double> result = List<double>.from(outputBuffer[0]);
    
    return result;
  }
  
  void close() {
    _interpreter?.close();
  }
}