import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Variantes visuais do [AppButton].
enum AppButtonVariant {
  /// Ação principal — fundo verde sólido.
  primary,

  /// Ação secundária — contorno.
  secondary,

  /// Ação destrutiva — vermelho.
  danger,
}

/// Botão padrão do AGdata.
///
/// Encapsula altura mínima (48dp+), ícone opcional, largura total e estado de
/// carregamento. Centraliza o estilo para que as telas não repitam
/// `ElevatedButton.styleFrom(...)` inline.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;

  /// Ocupa toda a largura disponível.
  final bool expand;

  /// Exibe spinner e desabilita o toque.
  final bool loading;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.expand = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !loading;
    final child = loading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : _content();

    final Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          child: child,
        );
        break;
      case AppButtonVariant.danger:
        button = ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
          ),
          child: child,
        );
        break;
      case AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          child: child,
        );
        break;
    }

    if (!expand) return button;
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: button,
    );
  }

  Widget _content() {
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
