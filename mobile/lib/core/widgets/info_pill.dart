import 'package:flutter/material.dart';
import '../theme/app_dimens.dart';

/// Chip informativo genérico (ícone + texto) com cores configuráveis.
///
/// Usado para metadados como localização GPS, status de sincronização e
/// avisos de conectividade. Centraliza o padrão "caixinha colorida com texto".
class InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  /// Cor do ícone e do texto.
  final Color color;

  /// Cor de fundo da pílula.
  final Color background;

  const InfoPill({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
