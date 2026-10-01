import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../clima/presentation/clima_card.dart';
import '../widgets/sync_status_button.dart';
import 'selecao_talhao_screen.dart';
import 'historico_screen.dart';
import 'mapa_screen.dart';

/// Tela inicial do AGdata — barra de marca fixa, acesso principal ao mapa
/// (central de controle) e demais ações em lista. Menu lateral reservado
/// para dados futuros de usuário/empresa.
class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  void _ir(BuildContext context, Widget tela) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => tela));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const _AppDrawer(),
      body: Column(
        children: [
          const _TopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ClimaCard(),
                  const SizedBox(height: AppSpacing.xl),
                  _MapControlCard(onTap: () => _ir(context, const MapaScreen())),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Ações rápidas',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  _ActionTile(
                    icon: Icons.center_focus_strong_outlined,
                    title: 'Nova Análise',
                    subtitle: 'Capturar e diagnosticar uma amostra',
                    accent: AppColors.primary,
                    onTap: () => _ir(context, const SelecaoTalhaoScreen()),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ActionTile(
                    icon: Icons.history,
                    title: 'Histórico',
                    subtitle: 'Relatórios e leituras salvas',
                    accent: AppColors.info,
                    onTap: () => _ir(context, const HistoricoScreen()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra superior fixa com a marca (verde, cantos inferiores arredondados).
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.sm, topInset + AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.eco, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AGdata',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        )),
                Text('Diagnóstico fitossanitário da soja',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        )),
              ],
            ),
          ),
          const SyncStatusButton(),
        ],
      ),
    );
  }
}

/// Cartão grande de acesso ao mapa — "central de controle" dos focos.
class _MapControlCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MapControlCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: SizedBox(
          height: 190,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Fundo verde.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3C8C40), AppColors.primaryDark],
                    ),
                  ),
                ),
                // Malha simbolizando um mapa.
                CustomPaint(
                  painter: _MalhaMapaPainter(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                // Botão central com ícone de mapa.
                Center(
                  child: Container(
                    height: 72,
                    width: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
                          width: 1.5),
                    ),
                    child: const Icon(Icons.map_outlined,
                        color: Colors.white, size: 38),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Desenha uma malha (grade) leve para simbolizar um mapa.
class _MalhaMapaPainter extends CustomPainter {
  final Color color;
  const _MalhaMapaPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const passo = 30.0;
    for (double x = 0; x <= size.width; x += passo) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += passo) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_MalhaMapaPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Item de ação em formato de lista (ícone + título + subtítulo + seta).
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
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
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menu lateral — reservado para dados futuros de usuário/empresa.
class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(AppSpacing.lg,
                MediaQuery.of(context).padding.top + AppSpacing.xl,
                AppSpacing.lg, AppSpacing.lg),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person_outline,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Conta',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                Text('Disponível em breve',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                const _DrawerItem(
                  icon: Icons.person_outline,
                  title: 'Dados do usuário',
                  emBreve: true,
                ),
                const _DrawerItem(
                  icon: Icons.business_outlined,
                  title: 'Dados da empresa',
                  emBreve: true,
                ),
                const _DrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Configurações',
                  emBreve: true,
                ),
                const Divider(),
                _DrawerItem(
                  icon: Icons.info_outline,
                  title: 'Sobre o AGdata',
                  onTap: () {
                    Navigator.pop(context);
                    showAboutDialog(
                      context: context,
                      applicationName: 'AGdata',
                      applicationVersion: '1.0.0',
                      applicationIcon:
                          const Icon(Icons.eco, color: AppColors.primary),
                      children: const [
                        Text(
                            'Ferramenta offline-first de diagnóstico fitossanitário da soja.'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool emBreve;
  final VoidCallback? onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.emBreve = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = !emBreve;
    return ListTile(
      enabled: enabled,
      leading: Icon(icon,
          color: enabled ? AppColors.textSecondary : AppColors.textTertiary),
      title: Text(title),
      trailing: emBreve
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const Text('Em breve',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary)),
            )
          : null,
      onTap: onTap,
    );
  }
}
