import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/diagnostico_visuals.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/section_header.dart';
import '../controllers/mapa_controller.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final MapaController _controller = MapaController();
  final MapController _mapController = MapController();

  static const List<String> _tiposDoenca = [
    "SAUDÁVEL",
    "FERRUGEM",
    "OÍDIO",
    "MANCHA ALVO",
    "INCONCLUSIVO"
  ];

  Future<String> _getPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Reenquadra a câmera para abranger todas as ocorrências visíveis.
  void _reenquadrar() {
    final pts = _controller.pontos;
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      _mapController.move(pts.first, 16);
    } else {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(pts),
          padding: const EdgeInsets.all(60),
        ),
      );
    }
  }

  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String? tempTalhao = _controller.filtroTalhao;
        String? tempDoenca = _controller.filtroDoenca;
        DateTime? tempInicio = _controller.dataInicio;
        DateTime? tempFim = _controller.dataFim;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Filtrar mapa",
                          style: Theme.of(context).textTheme.titleLarge),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(),
                  const SectionHeader(title: "Talhão"),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: tempTalhao,
                    hint: const Text("Todos os talhões"),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("Todos")),
                      ..._controller.talhoes.map((t) =>
                          DropdownMenuItem(value: t.nome, child: Text(t.nome)))
                    ],
                    onChanged: (val) => setModalState(() => tempTalhao = val),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeader(title: "Diagnóstico"),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _tiposDoenca.map((tipo) {
                      final v = DiagnosticoVisual.fromResultado(tipo);
                      final selecionado = tempDoenca == tipo;
                      return ChoiceChip(
                        avatar: Icon(v.icon,
                            size: 18,
                            color: selecionado
                                ? v.color
                                : AppColors.textTertiary),
                        label: Text(v.label),
                        selected: selecionado,
                        selectedColor: v.container,
                        onSelected: (selected) => setModalState(
                            () => tempDoenca = selected ? tipo : null),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: "Limpar",
                          variant: AppButtonVariant.secondary,
                          onPressed: () {
                            _controller.aplicarFiltros();
                            Navigator.pop(context);
                            _reenquadrar();
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppButton(
                          label: "Filtrar",
                          onPressed: () {
                            _controller.aplicarFiltros(
                                talhao: tempTalhao,
                                doenca: tempDoenca,
                                inicio: tempInicio,
                                fim: tempFim);
                            Navigator.pop(context);
                            _reenquadrar();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de ocorrências'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar mapa',
            onPressed: _abrirFiltros,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _reenquadrar,
        tooltip: 'Centralizar nas ocorrências',
        child: const Icon(Icons.center_focus_strong),
      ),
      body: FutureBuilder<String>(
        future: _getPath(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final cachePath = snapshot.data!;

          return ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              if (_controller.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              return Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _controller.centroMapa,
                      // ~100-150 m de visão ao abrir (nível de talhão).
                      initialZoom: 19.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.agdata.app',
                        // OSM serve tiles até z19; acima disso, faz upscale.
                        maxNativeZoom: 19,
                        tileProvider: CachedTileProvider(
                          store: HiveCacheStore(
                            cachePath,
                            hiveBoxName: 'agdata_tiles',
                          ),
                          // Expira o visual do mapa após 30 dias.
                          maxStale: const Duration(days: 30),
                        ),
                      ),
                      CircleLayer(circles: _controller.circles),
                      MarkerLayer(markers: _controller.markers),
                    ],
                  ),
                  _ContextoChip(
                    talhao: _controller.filtroTalhao,
                    total: _controller.totalVisiveis,
                  ),
                  if (_controller.contagemDoenca.isNotEmpty)
                    _Legenda(contagem: _controller.contagemDoenca),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Chip no topo informando o talhão exibido e o total de ocorrências.
class _ContextoChip extends StatelessWidget {
  final String? talhao;
  final int total;
  const _ContextoChip({required this.talhao, required this.total});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: AppSpacing.md,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco, size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${talhao ?? 'Todos os talhões'} · $total ocorrência(s)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Legenda das cores de diagnóstico presentes no mapa, com contagem.
class _Legenda extends StatelessWidget {
  final Map<String, int> contagem;
  const _Legenda({required this.contagem});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: AppSpacing.md,
      bottom: AppSpacing.md,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Legenda',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            ...contagem.entries.map((e) {
              final v = DiagnosticoVisual.fromResultado(e.key);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: v.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('${e.key} (${e.value})',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
