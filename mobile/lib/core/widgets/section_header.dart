import 'package:flutter/material.dart';
import '../theme/app_dimens.dart';

/// Cabeçalho de seção (rótulo em destaque + widget opcional à direita).
///
/// Padroniza títulos como "Tipo de Análise:", "Talhão:" nos filtros e seções.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
