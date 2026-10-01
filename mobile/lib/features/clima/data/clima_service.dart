import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Condição atual + previsão dos próximos dias.
class ClimaAtual {
  final double temperatura;
  final double umidade;
  final double vento;
  final int codigo;
  final List<PrevisaoDia> previsao;

  ClimaAtual({
    required this.temperatura,
    required this.umidade,
    required this.vento,
    required this.codigo,
    required this.previsao,
  });
}

class PrevisaoDia {
  final DateTime data;
  final int codigo;
  final double max;
  final double min;

  PrevisaoDia({
    required this.data,
    required this.codigo,
    required this.max,
    required this.min,
  });
}

/// Descrição + ícone para um código de tempo (WMO).
class ClimaInfo {
  final String descricao;
  final IconData icone;
  const ClimaInfo(this.descricao, this.icone);
}

/// Cliente da Open-Meteo (gratuita, sem chave de API).
class ClimaService {
  Future<ClimaAtual> buscar(double lat, double lon) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min'
      '&timezone=auto&forecast_days=4',
    );

    final resp = await http.get(uri).timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) {
      throw Exception('Falha ao consultar o clima (${resp.statusCode}).');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;

    final tempos = (daily['time'] as List).cast<String>();
    final codigos = (daily['weather_code'] as List).cast<num>();
    final maximas = (daily['temperature_2m_max'] as List).cast<num>();
    final minimas = (daily['temperature_2m_min'] as List).cast<num>();

    final previsao = <PrevisaoDia>[
      for (int i = 0; i < tempos.length; i++)
        PrevisaoDia(
          data: DateTime.parse(tempos[i]),
          codigo: codigos[i].toInt(),
          max: maximas[i].toDouble(),
          min: minimas[i].toDouble(),
        ),
    ];

    return ClimaAtual(
      temperatura: (current['temperature_2m'] as num).toDouble(),
      umidade: (current['relative_humidity_2m'] as num).toDouble(),
      vento: (current['wind_speed_10m'] as num).toDouble(),
      codigo: (current['weather_code'] as num).toInt(),
      previsao: previsao,
    );
  }

  /// Geocodificação reversa (BigDataCloud, gratuita e sem chave).
  /// Retorna "Cidade, UF" — ou null se indisponível (best-effort).
  Future<String?> buscarCidade(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client'
        '?latitude=$lat&longitude=$lon&localityLanguage=pt',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final cidade = (json['city'] as String?)?.trim();
      final local = (json['locality'] as String?)?.trim();
      final nome = (cidade != null && cidade.isNotEmpty)
          ? cidade
          : (local != null && local.isNotEmpty ? local : null);
      if (nome == null) return null;

      // principalSubdivisionCode vem como "BR-PR" → UF "PR".
      final codigoUf = (json['principalSubdivisionCode'] as String?)?.trim();
      if (codigoUf != null && codigoUf.contains('-')) {
        return '$nome, ${codigoUf.split('-').last}';
      }
      return nome;
    } catch (_) {
      return null;
    }
  }
}

/// Mapeia o código WMO em descrição (PT) e ícone.
ClimaInfo climaInfo(int codigo) {
  switch (codigo) {
    case 0:
      return const ClimaInfo('Céu limpo', Icons.wb_sunny);
    case 1:
      return const ClimaInfo('Predom. limpo', Icons.wb_sunny);
    case 2:
      return const ClimaInfo('Parc. nublado', Icons.wb_cloudy);
    case 3:
      return const ClimaInfo('Nublado', Icons.cloud);
    case 45:
    case 48:
      return const ClimaInfo('Nevoeiro', Icons.cloud);
    case 51:
    case 53:
    case 55:
    case 56:
    case 57:
      return const ClimaInfo('Garoa', Icons.grain);
    case 61:
    case 63:
    case 65:
    case 66:
    case 67:
      return const ClimaInfo('Chuva', Icons.water_drop);
    case 71:
    case 73:
    case 75:
    case 77:
      return const ClimaInfo('Neve', Icons.ac_unit);
    case 80:
    case 81:
    case 82:
      return const ClimaInfo('Aguaceiros', Icons.grain);
    case 85:
    case 86:
      return const ClimaInfo('Neve', Icons.ac_unit);
    case 95:
      return const ClimaInfo('Trovoada', Icons.thunderstorm);
    case 96:
    case 99:
      return const ClimaInfo('Trovoada/granizo', Icons.thunderstorm);
    default:
      return const ClimaInfo('Indefinido', Icons.help_outline);
  }
}
