import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/diagnostico_badge.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_header.dart';
import '../../data/models/leitura_model.dart';
import '../../data/datasources/database_service.dart';
import 'leitura_detalhe_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoricoScreen extends StatefulWidget {
  /// Quando informado, restringe o histórico às leituras desse talhão.
  final String? talhaoInicial;

  const HistoricoScreen({super.key, this.talhaoInicial});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  final DatabaseService _databaseService = DatabaseService();

  List<LeituraModel> _todasLeituras = []; // Guarda TUDO que vem do banco
  List<LeituraModel> _leiturasFiltradas = []; // Guarda só o que passa no filtro

  final List<int> _selecionados = [];
  bool _loading = true;

  // --- VARIÁVEIS DOS FILTROS ---
  DateTime? _dataFiltro;
  String _doencaFiltro = 'Todas';
  double _confiancaFiltro = 0.0;
  final List<String> _opcoesDoenca = [
    'Todas',
    'FERRUGEM',
    'OÍDIO',
    'SAUDÁVEL',
    'MANCHA ALVO',
    'INCONCLUSIVO'
  ];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    var dados = await _databaseService.buscarTodasLeituras();
    // Restringe ao talhão de origem, quando aberto a partir da câmera.
    if (widget.talhaoInicial != null) {
      dados = dados.where((l) => l.talhao == widget.talhaoInicial).toList();
    }
    if (mounted) {
      setState(() {
        _todasLeituras = dados.reversed.toList();
        _leiturasFiltradas = List.from(_todasLeituras);
        _loading = false;
      });
    }
  }

  // --- LÓGICA DE FILTRAGEM ---
  void _aplicarFiltros() {
    setState(() {
      _selecionados.clear();
      _leiturasFiltradas = _todasLeituras.where((leitura) {
        bool passaData = true;
        if (_dataFiltro != null) {
          passaData = leitura.dataHora.year == _dataFiltro!.year &&
              leitura.dataHora.month == _dataFiltro!.month &&
              leitura.dataHora.day == _dataFiltro!.day;
        }

        bool passaDoenca = true;
        if (_doencaFiltro != 'Todas') {
          passaDoenca = leitura.resultadoIA == _doencaFiltro;
        }

        bool passaConfianca = leitura.confianca >= _confiancaFiltro;

        return passaData && passaDoenca && passaConfianca;
      }).toList();
    });
  }

  /// Agrupa as leituras filtradas por talhão, preservando a ordem (mais recente).
  Map<String, List<LeituraModel>> _agruparPorTalhao() {
    final grupos = <String, List<LeituraModel>>{};
    for (final l in _leiturasFiltradas) {
      final chave = l.talhao.trim().isEmpty ? 'Sem talhão' : l.talhao;
      grupos.putIfAbsent(chave, () => []).add(l);
    }
    return grupos;
  }

  // --- MENU INFERIOR DE FILTROS ---
  void _abrirMenuDeFiltros() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Filtrar leituras",
                          style: Theme.of(context).textTheme.titleLarge),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context))
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  const SectionHeader(title: "Filtrar por dia"),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _dataFiltro == null
                          ? "Todas as datas"
                          : "Dia: ${formatarData(_dataFiltro!)}",
                      style: TextStyle(
                          color: _dataFiltro == null
                              ? AppColors.textTertiary
                              : AppColors.textPrimary),
                    ),
                    trailing: const Icon(Icons.calendar_month,
                        color: AppColors.primary),
                    onTap: () async {
                      final DateTime? escolhida = await showDatePicker(
                        context: context,
                        initialDate: _dataFiltro ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (escolhida != null) {
                        setModalState(() => _dataFiltro = escolhida);
                        _aplicarFiltros();
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const SectionHeader(title: "Tipo de análise"),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _doencaFiltro,
                    items: _opcoesDoenca.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (novoValor) {
                      setModalState(() => _doencaFiltro = novoValor!);
                      _aplicarFiltros();
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SectionHeader(
                    title: "Grau de certeza mínimo",
                    trailing: Text("${(_confiancaFiltro * 100).toInt()}%",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ),
                  Slider(
                    value: _confiancaFiltro,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: (valor) {
                      setModalState(() => _confiancaFiltro = valor);
                      _aplicarFiltros();
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: "Limpar filtros",
                    icon: Icons.clear_all,
                    variant: AppButtonVariant.secondary,
                    onPressed: () {
                      setModalState(() {
                        _dataFiltro = null;
                        _doencaFiltro = 'Todas';
                        _confiancaFiltro = 0.0;
                      });
                      _aplicarFiltros();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            );
          });
        });
  }

  /// Abre o detalhe da leitura e recarrega a lista ao voltar (após editar/excluir).
  Future<void> _abrirDetalhe(LeituraModel leitura) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => LeituraDetalheScreen(leitura: leitura)),
    );
    await _carregarDados();
    if (mounted) _aplicarFiltros();
  }

  void _alternarSelecao(int id) {
    setState(() {
      if (_selecionados.contains(id)) {
        _selecionados.remove(id);
      } else {
        _selecionados.add(id);
      }
    });
  }

  Future<void> _enviarRelatorioWhatsApp() async {
    final itensMarcados =
        _leiturasFiltradas.where((l) => _selecionados.contains(l.id)).toList();
    if (itensMarcados.isEmpty) return;

    StringBuffer sb = StringBuffer();
    sb.writeln("📊 *Relatório AGdata - Inspeção de Campo*");
    sb.writeln("📅 *Data do Envio:* ${formatarDataHora(DateTime.now())}\n");
    sb.writeln(
        "⚠️ *Atenção:* ${itensMarcados.length} registro(s) selecionado(s).\n");

    for (int i = 0; i < itensMarcados.length; i++) {
      final item = itensMarcados[i];
      sb.writeln("*Foco ${i + 1} - ${item.resultadoIA}*");
      sb.writeln("Talhão: ${item.talhao}");
      sb.writeln("Precisão: ${(item.confianca * 100).toStringAsFixed(1)}%");
      if (item.observacao.trim().isNotEmpty) {
        sb.writeln("Obs.: ${item.observacao.trim()}");
      }
      final linkMapa =
          "https://www.google.com/maps/search/?api=1&query=${item.latitude},${item.longitude}";
      sb.writeln("📍 Localização: $linkMapa\n");
    }
    sb.writeln("Aguardando orientações de manejo. 🚜");

    final textoCodificado = Uri.encodeComponent(sb.toString());
    final url = Uri.parse("https://wa.me/?text=$textoCodificado");

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Não foi possível abrir o link');
      }
      setState(() => _selecionados.clear());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao abrir o WhatsApp.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _agruparPorTalhao();
    final talhoes = grupos.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.talhaoInicial == null
            ? 'Relatórios de campo'
            : 'Relatórios · ${widget.talhaoInicial}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar análises',
            onPressed: _abrirMenuDeFiltros,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Enviar via WhatsApp',
            onPressed: _selecionados.isEmpty ? null : _enviarRelatorioWhatsApp,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _leiturasFiltradas.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off,
                  title: 'Nenhuma análise encontrada',
                  message:
                      'Ajuste os filtros ou realize novas leituras no campo.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: talhoes.length,
                  itemBuilder: (context, index) {
                    final nome = talhoes[index];
                    final leituras = grupos[nome]!;
                    return _TalhaoGrupo(
                      nome: nome,
                      leituras: leituras,
                      selecionados: _selecionados,
                      onToggle: _alternarSelecao,
                      onAbrir: _abrirDetalhe,
                    );
                  },
                ),
    );
  }
}

/// Seção expansível de um talhão, contendo suas leituras.
class _TalhaoGrupo extends StatelessWidget {
  final String nome;
  final List<LeituraModel> leituras;
  final List<int> selecionados;
  final ValueChanged<int> onToggle;
  final ValueChanged<LeituraModel> onAbrir;

  const _TalhaoGrupo({
    required this.nome,
    required this.leituras,
    required this.selecionados,
    required this.onToggle,
    required this.onAbrir,
  });

  @override
  Widget build(BuildContext context) {
    final afetadas = leituras
        .where((l) => l.resultadoIA.toUpperCase().trim() != 'SAUDÁVEL')
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Theme(
        // Remove as divisórias padrão do ExpansionTile.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          leading: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.eco, color: AppColors.primary, size: 20),
          ),
          title: Text(nome, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(
            '${leituras.length} leitura(s) · $afetadas com foco',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          children: [
            for (final leitura in leituras)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _LeituraCard(
                  leitura: leitura,
                  selecionado: selecionados.contains(leitura.id),
                  data: formatarDataHora(leitura.dataHora),
                  onAbrir: () => onAbrir(leitura),
                  onToggle: () => onToggle(leitura.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Cartão de uma leitura (miniatura + diagnóstico + seleção).
class _LeituraCard extends StatelessWidget {
  final LeituraModel leitura;
  final bool selecionado;
  final String data;
  final VoidCallback onAbrir;
  final VoidCallback onToggle;

  const _LeituraCard({
    required this.leitura,
    required this.selecionado,
    required this.data,
    required this.onAbrir,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selecionado ? AppColors.primaryContainer : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: selecionado ? AppColors.primary : AppColors.outlineVariant,
          width: selecionado ? 2 : 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onAbrir,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                _Thumb(caminho: leitura.caminhoImagem),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DiagnosticoBadge(
                          resultado: leitura.resultadoIA, dense: true),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        "Confiança: ${(leitura.confianca * 100).toStringAsFixed(1)}%",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(data, style: Theme.of(context).textTheme.bodySmall),
                      if (leitura.observacao.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.notes,
                                size: 14, color: AppColors.textTertiary),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                leitura.observacao,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Checkbox(
                  value: selecionado,
                  onChanged: (_) => onToggle(),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Miniatura da imagem da leitura, com fallback para imagem quebrada.
class _Thumb extends StatelessWidget {
  final String caminho;
  const _Thumb({required this.caminho});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Image.file(
        File(caminho),
        height: 72,
        width: 72,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 72,
          width: 72,
          color: AppColors.surfaceVariant,
          child: const Icon(Icons.broken_image, color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
