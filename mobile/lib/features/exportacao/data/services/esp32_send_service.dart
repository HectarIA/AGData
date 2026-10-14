import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../diagnostico/data/models/leitura_model.dart';

/// Envia leituras para o ESP32 quando o celular está conectado na rede
/// própria dele (AP "AGData-ESP32", sem necessidade de internet).
class Esp32SendService {
  static const String _baseUrl = 'http://192.168.4.1';
  static const Duration _timeout = Duration(seconds: 5);
  static const Duration _timeoutUpload = Duration(seconds: 20);

  /// Envio de debug: manda só o JSON das leituras, pro ESP32 logar no
  /// Serial. Não grava no pendrive USB — ver [enviarShapefile] pra isso.
  Future<int> enviarLeituras(List<LeituraModel> leituras) async {
    final corpo = jsonEncode(leituras.map((l) => l.toMap()).toList());

    final resposta = await http
        .post(
          Uri.parse('$_baseUrl/upload'),
          headers: {'Content-Type': 'application/json'},
          body: corpo,
        )
        .timeout(_timeout);

    if (resposta.statusCode != 200) {
      throw Exception('ESP32 respondeu ${resposta.statusCode}: ${resposta.body}');
    }

    final json = jsonDecode(resposta.body) as Map<String, dynamic>;
    return json['recebidas'] as int;
  }

  /// Envia os 4 arquivos do shapefile (.shp/.shx/.dbf/.prj) pro ESP32, que
  /// os grava na imagem de pendrive USB exposta pra tela do pulverizador.
  Future<void> enviarShapefile(List<File> arquivos) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/upload-shapefile'),
    );

    for (final arquivo in arquivos) {
      final extensao = arquivo.path.split('.').last.toLowerCase();
      if (!['shp', 'shx', 'dbf', 'prj'].contains(extensao)) continue;
      request.files.add(
        await http.MultipartFile.fromPath(extensao, arquivo.path),
      );
    }

    final streamedResponse = await request.send().timeout(_timeoutUpload);
    final resposta = await http.Response.fromStream(streamedResponse);

    if (resposta.statusCode != 200) {
      throw Exception('ESP32 respondeu ${resposta.statusCode}: ${resposta.body}');
    }
  }
}
