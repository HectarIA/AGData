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
      // ATENÇÃO: Certifique-se que o arquivo 'modelo_soja.tflite' está dentro da pasta assets na raiz do projeto
      _interpreter = await Interpreter.fromAsset('assets/modelo_soja.tflite');
      debugPrint('✅ Cérebro da IA (Modelo) carregado com sucesso!');
      
      // Imprime o formato de entrada para conferência (ajuda a debugar)
      // Se der erro aqui, comente estas duas linhas abaixo
      var inputShape = _interpreter!.getInputTensor(0).shape;
      debugPrint("Formato esperado pela IA: $inputShape");
      
    } catch (e) {
      debugPrint('❌ Erro crítico ao carregar o modelo TFLite: $e');
      debugPrint('Verifique se o arquivo está na pasta assets e se o pubspec.yaml está configurado.');
    }
  }

  // Função principal que faz a previsão
  Future<List<double>> predict(File imageFile) async {
    // --- CORREÇÃO APLICADA AQUI ---
    // Se o cérebro ainda não ligou, força ele a ligar agora antes de continuar.
    if (_interpreter == null) {
      debugPrint("⚠️ Interpretador não estava pronto. Inicializando agora...");
      await loadModel();
      
      // Se mesmo tentando carregar, ele continuar nulo, cancela tudo para não travar o app.
      if (_interpreter == null) {
        debugPrint("⛔ Não foi possível realizar a previsão: Modelo não carregado.");
        return [];
      }
    }
    // -----------------------------

    // 1. Ler a imagem do arquivo
    var imageBytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) {
      debugPrint("Erro ao decodificar a imagem.");
      return [];
    }

    // 2. Redimensionar para o tamanho que a IA espera (224x224)
    img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224);
    
    // 3. Extrair os pixels e NORMALIZAR (Dividir por 255.0 é crucial para este modelo!)
    // Convertendo para float32 entre 0.0 e 1.0
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
    // Temos 3 classes, então é um array de [1, 3] preenchido com zeros.
    var outputBuffer = List.filled(1 * 3, 0.0).reshape([1, 3]);

    // 5. Rodar a previsão (A mágica acontece aqui)
    _interpreter!.run(input, outputBuffer);

    // 6. Retornar a lista de probabilidades (ex: [0.1, 0.85, 0.05])
    List<double> result = List<double>.from(outputBuffer[0]);
    
    return result;
  }
  
  // Função opcional para fechar o interpretador se sair da tela (libera memória)
  void close() {
    _interpreter?.close();
  }
}