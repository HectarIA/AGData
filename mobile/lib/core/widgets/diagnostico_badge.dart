import 'package:flutter/material.dart';
import '../theme/app_dimens.dart';
import '../theme/diagnostico_visuals.dart';

/// Pílula visual de um diagnóstico (ícone + rótulo coloridos).
///
/// Usa [DiagnosticoVisual] para mapear o resultado da IA em cor/ícone,
/// garantindo redundância visual (cor + ícone + texto) para acessibilidade.
///
/// - `dense: false` (padrão): pílula com fundo container e texto na cor forte.
/// - `dense: true`: versão compacta para listas.
class DiagnosticoBadge extends StatelessWidget {
  final String resultado;
  final bool dense;

  const DiagnosticoBadge({
    super.key,
    required this.resultado,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final v = DiagnosticoVisual.fromResultado(resultado);
    final double fontSize = dense ? 13 : 15;
    final double iconSize = dense ? 16 : 18;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? 4 : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: v.container,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(v.icon, size: iconSize, color: v.color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            v.label,
            style: TextStyle(
              color: v.color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
