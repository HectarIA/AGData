import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../diagnostico/data/models/leitura_model.dart';

/// Envia leituras para o ESP32 quando o celular está conectado na rede
/// própria dele (AP "AGData-ESP32", sem necessidade de internet).
class Esp32SendService {
  static const String _baseUrl = 'http://192.168.4.1';
  static const Duration _timeout = Duration(seconds: 5);

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
}
