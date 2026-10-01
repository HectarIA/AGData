import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../controllers/selecao_talhao_controller.dart';
import '../widgets/sync_status_button.dart';
import 'home_screen.dart';

class SelecaoTalhaoScreen extends StatefulWidget {
  const SelecaoTalhaoScreen({super.key});

  @override
  State<SelecaoTalhaoScreen> createState() => _SelecaoTalhaoScreenState();
}

class _SelecaoTalhaoScreenState extends State<SelecaoTalhaoScreen> {
  final SelecaoTalhaoController _controller = SelecaoTalhaoController();

  /// Abre a tela de análise para o talhão e recarrega as estatísticas ao voltar.
  Future<void> _iniciarAnalise(String talhao) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(talhaoAtual: talhao)),
    );
    await _controller.recarregar();
  }

  Future<void> _abrirFormNovoTalhao() async {
    final textController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final podeSalvar = textController.text.trim().isNotEmpty;
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(Icons.agriculture_outlined,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Novo talhão',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              Text('Cadastre uma área de monitoramento',
                                  style:
                                      Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Nome do talhão',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: textController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Ex: Lote Sul, Gleba 03...',
                        prefixIcon: Icon(Icons.eco_outlined),
                      ),
                      onChanged: (_) => setSheetState(() {}),
                      onSubmitted: (_) {
                        if (podeSalvar) _salvarTalhao(textController.text);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Cancelar',
                            variant: AppButtonVariant.secondary,
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppButton(
                            label: 'Salvar',
                            icon: Icons.check,
                            onPressed: podeSalvar
                                ? () => _salvarTalhao(textController.text)
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _salvarTalhao(String nome) async {
    final limpo = nome.trim();
    if (limpo.isEmpty) return;
    await _controller.salvarTalhao(limpo);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar área'),
        actions: const [SyncStatusButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormNovoTalhao,
        icon: const Icon(Icons.add),
        label: const Text('Novo talhão'),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.talhoes.isEmpty) {
            return EmptyState(
              icon: Icons.agriculture_outlined,
              title: 'Nenhum talhão cadastrado',
              message: 'Crie a primeira área para iniciar o monitoramento.',
              action: AppButton(
                label: 'Cadastrar talhão',
                icon: Icons.add,
                expand: false,
                onPressed: _abrirFormNovoTalhao,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
            itemCount: _controller.talhoes.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    'Toque em um talhão para iniciar a análise',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              final talhao = _controller.talhoes[index - 1];
              return _TalhaoCard(
                nome: talhao.nome,
                dataCriacao: talhao.dataCriacao,
                ultimaLeitura: _controller.ultimaLeitura[talhao.nome],
                totalLeituras: _controller.totalLeituras[talhao.nome] ?? 0,
                onTap: () => _iniciarAnalise(talhao.nome),
              );
            },
          );
        },
      ),
    );
  }
}

/// Cartão de um talhão com metadados (criação, última leitura, total).
class _TalhaoCard extends StatelessWidget {
  final String nome;
  final DateTime dataCriacao;
  final DateTime? ultimaLeitura;
  final int totalLeituras;
  final VoidCallback onTap;

  const _TalhaoCard({
    required this.nome,
    required this.dataCriacao,
    required this.ultimaLeitura,
    required this.totalLeituras,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.eco, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nome, style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    _MetaLinha(
                      icon: Icons.event_outlined,
                      texto: 'Criado em ${formatarData(dataCriacao)}',
                    ),
                    const SizedBox(height: 2),
                    _MetaLinha(
                      icon: Icons.history,
                      texto: ultimaLeitura == null
                          ? 'Nenhuma leitura ainda'
                          : 'Última leitura: ${formatarDataHora(ultimaLeitura!)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text('$totalLeituras',
                        style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: AppColors.textTertiary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaLinha extends StatelessWidget {
  final IconData icon;
  final String texto;
  const _MetaLinha({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(texto,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
