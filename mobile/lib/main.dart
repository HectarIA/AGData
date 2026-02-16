import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'classifier.dart'; 

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  File? _image;
  final _picker = ImagePicker();
  
  // Instância do classificador
  final Classifier _classifier = Classifier();

  String _resultado = "Tire uma foto";
  String _confianca = "para analisar a soja";
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _classifier.loadModel();
  }

  // Função auxiliar para definir a cor do texto com base na doença
  Color _pegarCorResultado(String resultado) {
    switch (resultado) {
      case "SAUDÁVEL":
        return Colors.green;
      case "FERRUGEM":
        return Colors.red;
      case "OÍDIO":
        return Colors.orange[700]!; // Um laranja escuro alerta bem o produtor
      default:
        return Colors.grey[700]!;
    }
  }

  // --- LÓGICA DE CLASSIFICAÇÃO ---
  Future<void> _classificarImagem(File image) async {
    setState(() {
      _loading = true;
      _resultado = "Analisando...";
      _confianca = "";
    });

    List<double> output = await _classifier.predict(image);

    setState(() {
      _loading = false;

      if (output.isEmpty) {
        _resultado = "Erro na análise";
        return;
      }

      // --- NOVA LISTA DE DOENÇAS (Ordem exata do treino) ---
      List<String> labels = ["Ferrugem", "Oídio", "Saudável"]; 

      double maiorValor = 0.0;
      int indexGanhador = -1;

      // Argmax: Encontra a maior probabilidade e a posição dela
      for (int i = 0; i < output.length; i++) {
        if (output[i] > maiorValor) {
          maiorValor = output[i];
          indexGanhador = i;
        }
      }

      if (indexGanhador != -1) {
        // Se a IA tiver menos de 50% de certeza, consideramos inconclusivo
        if (maiorValor < 0.5) {
             _resultado = "Inconclusivo";
             _confianca = "Tente melhorar a iluminação e focar na folha";
        } else {
             String nomeResultado = indexGanhador < labels.length 
                 ? labels[indexGanhador] 
                 : "Desconhecido";

             _resultado = nomeResultado.toUpperCase();
             _confianca = "${(maiorValor * 100).toStringAsFixed(1)}% de certeza";
        }
      } else {
        _resultado = "Não identificado";
      }
    });
  }

  // --- LÓGICA DA CÂMERA/GALERIA ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      
      if (pickedFile != null) {
        File imagemTemporaria = File(pickedFile.path);
        
        setState(() {
          _image = imagemTemporaria;
        });
        
        _classificarImagem(imagemTemporaria);
      }
    } catch (e) {
      debugPrint("Erro ao pegar imagem: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detector AGdata', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- PREVIEW DA IMAGEM ---
              if (_image != null)
                Container(
                  height: 300,
                  width: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.green, width: 3),
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(_image!), 
                      fit: BoxFit.cover
                    ),
                  ),
                )
              else
                Container(
                   height: 300,
                   width: 300,
                   decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey, width: 2),
                   ),
                   child: const Column( 
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.add_a_photo, size: 60, color: Colors.grey),
                       SizedBox(height: 10),
                       Text("Sem imagem", style: TextStyle(color: Colors.grey))
                     ],
                   ),
                ),
              
              const SizedBox(height: 30),
              
              // --- RESULTADOS ---
              _loading 
                ? const CircularProgressIndicator(color: Colors.green)
                : Column(
                    children: [
                      Text(
                        _resultado,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _pegarCorResultado(_resultado), // Cor dinâmica!
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _confianca,
                        style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),

              const SizedBox(height: 40),
              
              // --- BOTÕES ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Câmera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white, // Deixa texto e ícone brancos
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.image),
                    label: const Text('Galeria'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white, // Deixa texto e ícone brancos
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}