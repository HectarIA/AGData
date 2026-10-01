import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/diagnostico_visuals.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/diagnostico_badge.dart';
import '../../../../core/widgets/info_pill.dart';
import '../controllers/home_controller.dart';
import '../widgets/observacao_field.dart';
import 'historico_screen.dart';
import 'mapa_screen.dart';

class HomeScreen extends StatefulWidget {
  final String talhaoAtual;
  const HomeScreen({super.key, required this.talhaoAtual});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _controller = HomeController();
  final TextEditingController _obsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.solicitarPermissoesIniciais();
    });
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final ok = await _controller.salvar(observacao: _obsController.text);
    if (!mounted) return;
    if (ok) {
      _obsController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leitura salva com sucesso!'),
          backgroundColor: AppColors.syncSuccess,
        ),
      );
    }
  }

  void _descartar() {
    _controller.descartar();
    _obsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.talhaoAtual),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Mapa de ocorrências',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const MapaScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Histórico de leituras',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        HistoricoScreen(talhaoInicial: widget.talhaoAtual))),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  _ImagePreview(image: _controller.image),
                  const SizedBox(height: AppSpacing.xl),
                  ..._buildEstado(_controller.status),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildEstado(DiagnosticoStatus status) {
    switch (status) {
      case DiagnosticoStatus.processando:
        return const [_LoadingCard()];

      case DiagnosticoStatus.revisao:
        return [
          _DiagnosticoRevisaoCard(
            resultado: _controller.resultado,
            confiancaValor: _controller.confiancaValor,
            localizacao: _controller.localizacaoTexto,
          ),
          const SizedBox(height: AppSpacing.lg),
          ObservacaoField(controller: _obsController),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Descartar',
                  icon: Icons.delete_outline,
                  variant: AppButtonVariant.secondary,
                  onPressed: _controller.salvando ? null : _descartar,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: 'Salvar',
                  icon: Icons.check,
                  loading: _controller.salvando,
                  onPressed: _salvar,
                ),
              ),
            ],
          ),
        ];

      case DiagnosticoStatus.erro:
        return [
          _MessageCard(
            titulo: _controller.resultado,
            subtitulo: _controller.mensagemErro,
            isErro: true,
          ),
          const SizedBox(height: AppSpacing.xl),
          ..._botoesCaptura(),
        ];

      case DiagnosticoStatus.inicial:
        return [
          const _MessageCard(
            titulo: 'Pronto para analisar',
            subtitulo: 'Capture ou selecione uma foto da soja.',
            isErro: false,
          ),
          const SizedBox(height: AppSpacing.xl),
          ..._botoesCaptura(),
        ];
    }
  }

  List<Widget> _botoesCaptura() {
    return [
      AppButton(
        label: 'Capturar foto',
        icon: Icons.camera_alt_outlined,
        onPressed: () => _controller.pickAndProcessImage(
            ImageSource.camera, widget.talhaoAtual),
      ),
      const SizedBox(height: AppSpacing.md),
      AppButton(
        label: 'Escolher da galeria',
        icon: Icons.photo_library_outlined,
        variant: AppButtonVariant.secondary,
        onPressed: () => _controller.pickAndProcessImage(
            ImageSource.gallery, widget.talhaoAtual),
      ),
    ];
  }
}

/// Área quadrada de pré-visualização da imagem (ou placeholder de captura).
class _ImagePreview extends StatelessWidget {
  final File? image;
  const _ImagePreview({required this.image});

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null;
    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: hasImage ? AppColors.primary : AppColors.outline,
            width: 2,
          ),
          image: hasImage
              ? DecorationImage(image: FileImage(image!), fit: BoxFit.cover)
              : null,
        ),
        child: hasImage
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined,
                      size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: AppSpacing.md),
                  Text('Pronto para analisar',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.lg),
            Text('Analisando amostra...',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('Processando imagem e localização',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Card de revisão do diagnóstico: badge + barra de precisão + GPS.
class _DiagnosticoRevisaoCard extends StatelessWidget {
  final String resultado;
  final double confiancaValor;
  final String localizacao;

  const _DiagnosticoRevisaoCard({
    required this.resultado,
    required this.confiancaValor,
    required this.localizacao,
  });

  @override
  Widget build(BuildContext context) {
    final visual = DiagnosticoVisual.fromResultado(resultado);
    final temGps =
        localizacao.isNotEmpty && localizacao != 'GPS indisponível';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: DiagnosticoBadge(resultado: resultado)),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Precisão da análise',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text('${(confiancaValor * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: visual.color, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: confiancaValor.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(visual.color),
              ),
            ),
            if (temGps) ...[
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: InfoPill(
                  icon: Icons.location_on_outlined,
                  text: localizacao,
                  color: AppColors.info,
                  background: AppColors.infoContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final bool isErro;

  const _MessageCard({
    required this.titulo,
    required this.subtitulo,
    required this.isErro,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = isErro ? AppColors.danger : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          if (isErro) ...[
            const Icon(Icons.error_outline,
                color: AppColors.danger, size: 32),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(color: color),
          ),
          if (subtitulo.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitulo,
                textAlign: TextAlign.center, style: textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
