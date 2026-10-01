class Leitura {
  final int id;
  final String resultadoIA;
  final double confianca;
  final String caminhoImagem;
  final DateTime dataHora;
  final double latitude;
  final double longitude;
  final String talhao;
  final String observacao;
  final bool sincronizado;

  Leitura({
    required this.id,
    required this.resultadoIA,
    required this.confianca,
    required this.caminhoImagem,
    required this.dataHora,
    required this.latitude,
    required this.longitude,
    required this.talhao,
    this.observacao = '',
    required this.sincronizado,
  });
}