import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/home_controller.dart';
import 'historico_screen.dart';
import 'mapa_screen.dart';

class HomeScreen extends StatefulWidget {
  final String talhaoAtual;
  const HomeScreen({super.key, required this.talhaoAtual});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _controller = HomeController();

  Color _pegarCorResultado(String resultado) {
    switch (resultado.toUpperCase()) {
      case "SAUDÁVEL": return Colors.green;
      case "FERRUGEM": return Colors.red;
      case "OÍDIO": return Colors.orange[700]!;
      case "INCONCLUSIVO": return Colors.yellow[800]!;
      case "MANCHA ALVO": return Colors.brown[700]!;
      default: return Colors.grey[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.talhaoAtual, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.map, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MapaScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.list_alt, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoricoScreen())),
          )
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 300, width: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _controller.image != null ? Colors.green : Colors.grey, width: 3),
                      image: _controller.image != null ? DecorationImage(image: FileImage(_controller.image!), fit: BoxFit.cover) : null,
                    ),
                    child: _controller.image == null
                        ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 60, color: Colors.grey), SizedBox(height: 10), Text("Pronto para analisar", style: TextStyle(color: Colors.grey))])
                        : null,
                  ),
                  const SizedBox(height: 30),
                  _controller.loading
                      ? const CircularProgressIndicator(color: Colors.green)
                      : Column(
                          children: [
                            Text(_controller.resultado, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _pegarCorResultado(_controller.resultado))),
                            const SizedBox(height: 5),
                            Text(_controller.confianca, style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 10),
                            if (_controller.localizacaoTexto.isNotEmpty && _controller.localizacaoTexto != "GPS indisponível")
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                                child: Text(_controller.localizacaoTexto, style: TextStyle(fontSize: 14, color: Colors.blue[800], fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _controller.pickAndProcessImage(ImageSource.camera, widget.talhaoAtual),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Câmara'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        onPressed: () => _controller.pickAndProcessImage(ImageSource.gallery, widget.talhaoAtual),
                        icon: const Icon(Icons.image),
                        label: const Text('Galeria'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}