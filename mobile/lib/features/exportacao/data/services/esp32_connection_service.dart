import 'package:wifi_iot/wifi_iot.dart';

/// Conecta o celular na rede Wi-Fi própria do ESP32 (SoftAP, sem internet)
/// antes do envio. Usado quando o ESP32 está embarcado na máquina/trator,
/// fora do alcance de qualquer roteador.
class Esp32ConnectionService {
  static const String _ssid = 'AGData-ESP32';
  static const String _senha = 'agdata123';

  /// Conecta na rede do ESP32 e força o tráfego do app por ela, mesmo que
  /// o Android prefira os dados móveis por essa rede não ter internet.
  /// Retorna true se a conexão foi estabelecida.
  Future<bool> conectar() async {
    final conectado = await WiFiForIoTPlugin.connect(
      _ssid,
      password: _senha,
      security: NetworkSecurity.WPA,
      joinOnce: true,
      withInternet: false,
    );

    if (conectado) {
      await WiFiForIoTPlugin.forceWifiUsage(true);
    }

    return conectado;
  }

  /// Libera o roteamento forçado pela rede do ESP32 após o envio, para o
  /// celular voltar a usar a rede/dados normais.
  Future<void> liberar() async {
    await WiFiForIoTPlugin.forceWifiUsage(false);
  }
}
