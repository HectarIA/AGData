import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart'; // Para as pastas seguras
import 'package:geolocator/geolocator.dart';
import '../classifier.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';
import '../models/leitura_model.dart';
import 'historico_screen.dart'; // <-- IMPORT DA TELA NOVA AQUI!

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  
  final Classifier _classifier = Classifier();
  final LocationService _locationService = LocationService();
  final DatabaseService _databaseService = DatabaseService();

  String _resultado = "Tire uma fotografia";
  String _confianca = "para analisar a soja";
  String _localizacaoTexto = ""; 
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _classifier.loadModel();
  }

  Color _pegarCorResultado(String resultado) {
    switch (resultado) {
      case "SAUDÁVEL": return Colors.green;
      case "FERRUGEM": return Colors.red;
      case "OÍDIO": return Colors.orange[700]!; 
      default: return Colors.grey[700]!;
    }
  }

  Future<void> _processarImagem(File image) async {
    setState(() {
      _loading = true;
      _resultado = "A analisar...";
      _confianca = "";
      _localizacaoTexto = "A buscar satélite... 🛰️"; 
    });

    // 1. Executa inferência e busca de GPS simultaneamente
    List<double> output = await _classifier.predict(image);
    Position? pos = await _locationService.getCurrentPosition();

    // 2. Trata as coordenadas
    double lat = 0.0;
    double lng = 0.0;
    String locTexto = "GPS indisponível";
    
    if (pos != null) {
      lat = pos.latitude;
      lng = pos.longitude;
      locTexto = "📍 Lat: ${lat.toStringAsFixed(5)} | Lng: ${lng.toStringAsFixed(5)}";
    }

    // 3. Lógica da IA para achar o vencedor
    List<String> labels = ["Ferrugem", "Oídio", "Saudável"]; 
    double maiorValor = 0.0;
    int indexGanhador = -1;

    for (int i = 0; i < output.length; i++) {
      if (output[i] > maiorValor) {
        maiorValor = output[i];
        indexGanhador = i;
      }
    }

    String nomeFinal = "Não identificado";
    if (output.isNotEmpty && indexGanhador != -1) {
      if (maiorValor < 0.5) {
        nomeFinal = "Inconclusivo";
      } else {
        nomeFinal = indexGanhador < labels.length ? labels[indexGanhador] : "Desconhecido";
      }
    }

    // --- MAGIA DO BANCO DE DADOS COMEÇA AQUI ---
    // 4. Copiar a imagem para o diretório seguro (para não apagar do Histórico)
    final appDir = await getApplicationDocumentsDirectory();
    final nomeFicheiro = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final imagemGuardada = await image.copy('${appDir.path}/$nomeFicheiro');

    // 5. Criar o registo e guardar no Isar
    final novaLeitura = LeituraModel()
      ..resultadoIA = nomeFinal.toUpperCase()
      ..confianca = maiorValor // Guardamos o valor puro (ex: 0.95) para facilitar contas futuras
      ..caminhoImagem = imagemGuardada.path
      ..dataHora = DateTime.now()
      ..latitude = lat
      ..longitude = lng
      ..sincronizado = false;

    await _databaseService.guardarLeitura(novaLeitura);
    debugPrint("✅ Leitura guardada com sucesso no Isar!");
    // --- MAGIA TERMINA AQUI ---

    // 6. Atualizar o Ecrã
    setState(() {
      _loading = false;
      _localizacaoTexto = locTexto;

      if (nomeFinal == "Inconclusivo") {
        _resultado = nomeFinal;
        _confianca = "Tente melhorar a iluminação e focar na folha";
      } else {
        _resultado = nomeFinal.toUpperCase();
        _confianca = "${(maiorValor * 100).toStringAsFixed(1)}% de certeza";
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        File imagemTemporaria = File(pickedFile.path);
        setState(() => _image = imagemTemporaria);
        _processarImagem(imagemTemporaria);
      }
    } catch (e) {
      debugPrint("Erro ao capturar imagem: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detector AGdata', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
        actions: [
          // <-- BOTÃO NOVO AQUI! Ao clicar, abre o Histórico
          IconButton(
            icon: const Icon(Icons.list_alt, color: Colors.white),
            tooltip: 'Abrir Histórico',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoricoScreen()),
              );
            },
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_image != null)
                Container(
                  height: 300, width: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.green, width: 3),
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(image: FileImage(_image!), fit: BoxFit.cover),
                  ),
                )
              else
                Container(
                   height: 300, width: 300,
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
              
              _loading 
                ? const CircularProgressIndicator(color: Colors.green)
                : Column(
                    children: [
                      Text(
                        _resultado,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _pegarCorResultado(_resultado)),
                      ),
                      const SizedBox(height: 5),
                      Text(_confianca, style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 10),
                      if (_localizacaoTexto.isNotEmpty && _localizacaoTexto != "GPS indisponível")
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                          child: Text(_localizacaoTexto, style: TextStyle(fontSize: 14, color: Colors.blue[800], fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),

              const SizedBox(height: 40),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Câmara'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white, 
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
                      foregroundColor: Colors.white, 
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