/// Calcula a taxa de aplicação (L/ha de calda) recomendada por diagnóstico,
/// para compor o mapa de prescrição enviado ao pulverizador.
///
/// Valores de referência (não são dose exata de um produto comercial — ver
/// TCC para a justificativa agronômica completa e a recomendação de
/// calibração com um agrônomo/bula antes de uso real em campo):
/// - Ferrugem Asiática: ensaios Embrapa (Passo Fundo) usam ~130-150 L/ha de
///   calda com adjuvante; é a doença de maior importância econômica da soja
///   no Brasil, tratamento sempre justificado.
/// - Mancha Alvo: Circular Técnica Embrapa 203/2023-24 cita FOX XPRO a
///   0,5 L/ha de produto, aplicado tipicamente em ~150 L/ha de calda.
/// - Mancha Parda (Septoriose): Circular Técnica Embrapa 205 cita
///   clorotalonil a 1,5 L/ha de produto, calda também na faixa de 150 L/ha.
/// - Oídio: a Embrapa historicamente classifica como doença de baixa
///   importância econômica na soja, frequentemente sem recomendação de
///   controle químico — por isso dose 0 (evita aplicação desnecessária).
/// - Saudável: 0 L/ha (bicos fechados).
class DoseService {
  /// Abaixo deste limiar, a dose automática é mantida mas marcada para
  /// revisão manual do operador antes da aplicação (padrão de uso seguro:
  /// a IA sempre sugere, o humano sempre pode confirmar ou sobrescrever).
  static const double limiarConfianca = 0.70;

  static const double _doseComTratamento = 150.0;
  static const double _doseSemTratamento = 0.0;

  static const Map<String, double> _dosesPorDoenca = {
    'SAUDAVEL': _doseSemTratamento,
    'OIDIO': _doseSemTratamento,
    'FERRUGEM': _doseComTratamento,
    'MANCHA_ALVO': _doseComTratamento,
    'SEPTORIA': _doseComTratamento,
  };

  /// Retorna a dose recomendada (L/ha) para uma doença conhecida. Doenças
  /// não reconhecidas (ex: "INCONCLUSIVO") retornam 0, por segurança.
  double calcularDose(String doenca) {
    return _dosesPorDoenca[doenca.toUpperCase()] ?? _doseSemTratamento;
  }

  /// Indica se a leitura precisa de revisão manual antes da aplicação:
  /// confiança abaixo do limiar, ou doença não reconhecida pela tabela.
  bool precisaRevisao(String doenca, double confianca) {
    final doencaConhecida = _dosesPorDoenca.containsKey(doenca.toUpperCase());
    return confianca < limiarConfianca || !doencaConhecida;
  }
}
