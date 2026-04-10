import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/controller/session_controller.dart';
import '../../../auth/data/models/auth_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/pages/super_admin_page.dart';
import '../../../auth/presentation/pages/admin_page.dart';

class CustomDrawer extends StatelessWidget {
  final VoidCallback? onSync;
  final bool isSyncing;

  const CustomDrawer({
    super.key,
    this.onSync,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    final session = sl<SessionController>();
    final user = session.usuario;
    final bool isSuperAdmin = user?.role == UserRole.superAdmin;
    final bool isAdmin = user?.role == UserRole.admin;
    final bool temAcessoGestao = isSuperAdmin || isAdmin;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            margin: EdgeInsets.zero, // Remove margens extras que podem causar desalinhamento
            decoration: BoxDecoration(
              color: isSuperAdmin ? const Color(0xFF1B5E20) : const Color(0xFF2E7D32),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                isSuperAdmin ? Icons.admin_panel_settings : Icons.person,
                color: isSuperAdmin ? const Color(0xFF1B5E20) : const Color(0xFF2E7D32),
                size: 40,
              ),
            ),
            // BUG FIX: Removi a Column complexa do accountName que causava o overflow.
            // Agora o nome e a empresa são tratados de forma que o Header gerencie o espaço.
            accountName: Text(
              user?.name ?? 'Usuário',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(user?.email ?? ''),
                if (!isSuperAdmin && user?.companyId != null)
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('companies')
                        .doc(user!.companyId)
                        .get(),
                    builder: (context, snapshot) {
                      String empresa = snapshot.hasData && snapshot.data!.exists
                          ? (snapshot.data!.data() as Map<String, dynamic>)['name'] ?? 'Empresa'
                          : "...";
                      return Text(
                        empresa,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          // OPÇÃO DE SINCRONIZAÇÃO
          if (onSync != null)
            ListTile(
              leading: isSyncing
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync, color: Colors.green),
              title: const Text("Sincronizar Dados"),
              onTap: isSyncing ? null : () {
                Navigator.pop(context);
                onSync!();
              },
            ),

          // ÁREA DE GESTÃO (FILTRADA POR ROLE)
          if (temAcessoGestao) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
              child: Text("ADMINISTRAÇÃO", 
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            ListTile(
              leading: Icon(isSuperAdmin ? Icons.domain : Icons.people, color: Colors.blue),
              title: Text(isSuperAdmin ? "Painel Global" : "Gerenciar Operadores"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => isSuperAdmin ? const SuperAdminPage() : const AdminPage(),
                  ),
                );
              },
            ),
          ],

          const Spacer(),
          const Divider(),
          
          // BOTÃO DE SAIR UNIFICADO
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Sair da Conta", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () => _confirmarSair(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _confirmarSair(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sair?"),
        content: const Text("Deseja realmente encerrar sua sessão?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await sl<AuthRepository>().logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            child: const Text("SAIR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}