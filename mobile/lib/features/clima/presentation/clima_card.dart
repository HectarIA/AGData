import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../diagnostico/data/datasources/location_service.dart';
import '../data/clima_service.dart';

/// Card de clima da tela inicial: condição atual, previsão e botão de atualizar.
class ClimaCard extends StatefulWidget {
  const ClimaCard({super.key});

  @override
  State<ClimaCard> createState() => _ClimaCardState();
}

class _ClimaCardState extends State<ClimaCard> {
  final LocationService _location = LocationService();
  final ClimaService _service = ClimaService();

  bool _carregando = true;
  String? _erro;
  ClimaAtual? _clima;
  String? _cidade;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final pos = await _location.getCurrentPosition();
      if (pos == null) {
        _falhar('Não foi possível obter a localização.');
        return;
      }
      final clima = await _service.buscar(pos.latitude, pos.longitude);
      final cidade = await _service.buscarCidade(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _clima = clima;
        _cidade = cidade;
        _carregando = false;
      });
    } catch (_) {
      _falhar('Não foi possível obter o clima.');
    }
  }

  void _falhar(String msg) {
    if (!mounted) return;
    setState(() {
      _erro = msg;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_cloudy_outlined,
                    color: AppColors.info, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Clima agora',
                          style: Theme.of(context).textTheme.titleMedium),
                      if (_cidade != null)
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: AppColors.textTertiary),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                _cidade!,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                _carregando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Atualizar clima',
                        onPressed: _carregar,
                      ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _conteudo(context),
          ],
        ),
      ),
    );
  }

  Widget _conteudo(BuildContext context) {
    if (_carregando && _clima == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text('Obtendo clima da sua localização...',
            style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    if (_erro != null) {
      return Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(_erro!,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          TextButton(onPressed: _carregar, child: const Text('Tentar')),
        ],
      );
    }

    final clima = _clima!;
    final info = climaInfo(clima.codigo);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(info.icone, size: 48, color: AppColors.info),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${clima.temperatura.round()}°C',
                    style: textTheme.displaySmall),
                Text(info.descricao, style: textTheme.bodyMedium),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _MetaClima(
                    icon: Icons.water_drop_outlined,
                    texto: '${clima.umidade.round()}%'),
                const SizedBox(height: AppSpacing.xs),
                _MetaClima(
                    icon: Icons.air,
                    texto: '${clima.vento.round()} km/h'),
              ],
            ),
          ],
        ),
        if (clima.previsao.isNotEmpty) ...[
          const Divider(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final dia in clima.previsao) _DiaPrevisao(dia: dia),
            ],
          ),
        ],
      ],
    );
  }
}

class _MetaClima extends StatelessWidget {
  final IconData icon;
  final String texto;
  const _MetaClima({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.xs),
        Text(texto, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _DiaPrevisao extends StatelessWidget {
  final PrevisaoDia dia;
  const _DiaPrevisao({required this.dia});

  static const _semana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final ehHoje = dia.data.year == hoje.year &&
        dia.data.month == hoje.month &&
        dia.data.day == hoje.day;
    final rotulo = ehHoje ? 'Hoje' : _semana[dia.data.weekday - 1];
    final info = climaInfo(dia.codigo);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(rotulo, style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Icon(info.icone, size: 22, color: AppColors.info),
        const SizedBox(height: AppSpacing.xs),
        Text('${dia.max.round()}°',
            style: textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        Text('${dia.min.round()}°', style: textTheme.bodySmall),
      ],
    );
  }
}
