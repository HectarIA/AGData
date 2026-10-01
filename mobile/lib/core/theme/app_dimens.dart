/// Tokens de espaçamento, raio e dimensões do AGdata.
///
/// Escala consistente de 4pt. Usar sempre estes valores em vez de números
/// soltos espalhados pelas telas.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16; // cantos suavemente arredondados (cards)
  static const double xl = 24; // bottom sheets
  static const double pill = 999;
}

class AppSizes {
  AppSizes._();

  /// Altura/alvo de toque mínimo para uso em campo (com luvas).
  static const double minTouchTarget = 48;

  /// Altura padrão de botões primários.
  static const double buttonHeight = 52;
}
