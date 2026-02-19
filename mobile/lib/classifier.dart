import 'dart:io';
import 'package:flutter/foundation.dart'; // Necessário para o debugPrint
import 'package:image/image.dart' as img; 
import 'package:tflite_flutter/tflite_flutter.dart';

class Classifier {
  // Variável para guardar o interpretador (o cérebro da IA)
  Interpreter? _interpreter;

  // Carrega o modelo da memória
  Future<void> loadModel() async {
    try {
      // ATENÇÃO: Nome do modelo atualizado para a versão 2!
      _interpreter = await Interpreter.fromAsset('assets/modelo_soja.tflite');
      debugPrint('✅ Modelo carregado com sucesso!');
      
      // Imprime o formato de entrada para conferência (ajuda a debugar)
      var inputShape = _interpreter!.getInputTensor(0).shape;
      debugPrint("Formato esperado pela IA: $inputShape");
      
    } catch (e) {
      debugPrint('❌ Erro ao carregar o modelo: $e');
    }
  }

  // Função principal que faz a previsão
  Future<List<double>> predict(File imageFile) async {
    if (_interpreter == null) {
      debugPrint("Interpretador não inicializado");
      return [];
    }

    // 1. Ler a imagem do arquivo
    var imageBytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) return [];

    // 2. Redimensionar para o tamanho que a IA espera (224x224)
    img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224);
    
    // 3. Extrair os pixels e NORMALIZAR (Dividir por 255.0 é crucial!)
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

    var outputBuffer = List.filled(1 * 3, 0.0).reshape([1, 3]);

    // 5. Rodar a previsão
    _interpreter!.run(input, outputBuffer);

    // 6. Retornar a lista de probabilidades
    List<double> result = List<double>.from(outputBuffer[0]);
    
    return result;
  }
}