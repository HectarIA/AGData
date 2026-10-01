import 'package:flutter/material.dart';

/// Tokens de cor do AGdata.
///
/// Fonte única da verdade para todas as cores do app. Nenhuma tela deve usar
/// `Color(0x...)` ou `Colors.green[700]` diretamente — sempre referenciar aqui.
///
/// Paleta pensada para **uso em campo sob luz solar direta**: superfícies
/// off-white (em vez de branco puro, que ofusca), textos escuros de alto
/// contraste e cores utilitárias fortes e saturadas.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Marca / Primária (verde orgânico)
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF2E7D32); // identidade atual
  static const Color primaryDark = Color(0xFF1B5E20); // hover/pressed, AppBar
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryContainer = Color(0xFFD7EAD9); // fundos sutis
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF0C3711);

  // ---------------------------------------------------------------------------
  // Superfícies / Neutros limpos
  // ---------------------------------------------------------------------------
  static const Color background = Color(0xFFF5F7F4); // off-white levemente verde
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEAEEE8); // cards alternativos
  static const Color outline = Color(0xFFCBD2C6); // bordas definidas
  static const Color outlineVariant = Color(0xFFE3E8DF);

  // ---------------------------------------------------------------------------
  // Texto (contraste reforçado — nada de cinza claro lavado)
  // ---------------------------------------------------------------------------
  static const Color textPrimary = Color(0xFF191D17); // quase preto
  static const Color textSecondary = Color(0xFF434A3F); // cinza escuro legível
  static const Color textTertiary = Color(0xFF6A7165); // metadados, captions
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Cores semânticas de DIAGNÓSTICO
  // Cada diagnóstico tem: cor forte (texto/ícone) + container (fundo do card).
  // Sempre acompanhadas de ícone — nunca depender só da cor (daltonismo).
  // ---------------------------------------------------------------------------
  static const Color saudavel = Color(0xFF2E7D32);
  static const Color saudavelContainer = Color(0xFFD7EAD9);

  static const Color ferrugem = Color(0xFFC62828); // alerta forte
  static const Color ferrugemContainer = Color(0xFFFBDAD7);

  static const Color oidio = Color(0xFFE65100); // laranja profundo
  static const Color oidioContainer = Color(0xFFFCE3D2);

  static const Color manchaAlvo = Color(0xFF6A4A36); // marrom (mancha-alvo)
  static const Color manchaAlvoContainer = Color(0xFFEDE0D6);

  static const Color inconclusivo = Color(0xFF5C5F58); // cinza neutro
  static const Color inconclusivoContainer = Color(0xFFE5E7E1);

  // ---------------------------------------------------------------------------
  // Status de SINCRONIZAÇÃO / conectividade
  // ---------------------------------------------------------------------------
  static const Color syncSuccess = Color(0xFF2E7D32); // verde vibrante
  static const Color syncPending = Color(0xFFF9A825); // âmbar
  static const Color syncError = Color(0xFFC62828); // vermelho
  static const Color offline = Color(0xFF6A7165); // cinza

  // ---------------------------------------------------------------------------
  // Utilitárias
  // ---------------------------------------------------------------------------
  static const Color info = Color(0xFF1565C0); // GPS / informações
  static const Color infoContainer = Color(0xFFD9E7F8);
  static const Color danger = Color(0xFFC62828); // ações destrutivas
}
