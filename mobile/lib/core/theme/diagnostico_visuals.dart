import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Representação visual de um diagnóstico fitossanitário.
///
/// Centraliza cor + cor de fundo + ícone + rótulo para cada resultado da IA.
/// Substitui as funções `_pegarCorResultado()` que estavam duplicadas (e
/// divergentes) em home_screen e historico_screen.
///
/// Uso: `DiagnosticoVisual.fromResultado(leitura.resultadoIA)`.
class DiagnosticoVisual {
  final String label;
  final Color color;
  final Color container;
  final IconData icon;

  const DiagnosticoVisual({
    required this.label,
    required this.color,
    required this.container,
    required this.icon,
  });

  /// `onColor` para texto/ícone sobre [color] — sempre branco (cores são fortes).
  Color get onColor => Colors.white;

  /// Diagnósticos reconhecidos pela IA (exclui mensagens de estado/erro).
  static const Set<String> conhecidos = {
    'SAUDÁVEL',
    'SAUDAVEL',
    'FERRUGEM',
    'OÍDIO',
    'OIDIO',
    'MANCHA ALVO',
    'INCONCLUSIVO',
  };

  /// True se [resultado] é um diagnóstico real (e não um texto de estado/erro).
  static bool isConhecido(String resultado) =>
      conhecidos.contains(resultado.toUpperCase().trim());

  static DiagnosticoVisual fromResultado(String resultado) {
    switch (resultado.toUpperCase().trim()) {
      case 'SAUDÁVEL':
      case 'SAUDAVEL':
        return const DiagnosticoVisual(
          label: 'Saudável',
          color: AppColors.saudavel,
          container: AppColors.saudavelContainer,
          icon: Icons.verified_outlined,
        );
      case 'FERRUGEM':
        return const DiagnosticoVisual(
          label: 'Ferrugem',
          color: AppColors.ferrugem,
          container: AppColors.ferrugemContainer,
          icon: Icons.warning_amber_rounded,
        );
      case 'OÍDIO':
      case 'OIDIO':
        return const DiagnosticoVisual(
          label: 'Oídio',
          color: AppColors.oidio,
          container: AppColors.oidioContainer,
          icon: Icons.coronavirus_outlined,
        );
      case 'MANCHA ALVO':
        return const DiagnosticoVisual(
          label: 'Mancha Alvo',
          color: AppColors.manchaAlvo,
          container: AppColors.manchaAlvoContainer,
          icon: Icons.adjust_outlined,
        );
      case 'INCONCLUSIVO':
        return const DiagnosticoVisual(
          label: 'Inconclusivo',
          color: AppColors.inconclusivo,
          container: AppColors.inconclusivoContainer,
          icon: Icons.help_outline,
        );
      default:
        return DiagnosticoVisual(
          label: resultado,
          color: AppColors.inconclusivo,
          container: AppColors.inconclusivoContainer,
          icon: Icons.science_outlined,
        );
    }
  }
}
