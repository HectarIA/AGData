import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/datasources/database_service.dart';
import '/../infra/repositories/sync_repository.dart';
import '/../infra/services/connectivity_service.dart';

/// Indicador de sincronização no AppBar.
///
/// Estados:
/// - sincronizando → spinner;
/// - offline → nuvem cortada;
/// - há pendentes (online) → nuvem com seta + contador (toque sincroniza);
/// - tudo enviado → nuvem verificada.
class SyncStatusButton extends StatefulWidget {
  const SyncStatusButton({super.key});

  @override
  State<SyncStatusButton> createState() => _SyncStatusButtonState();
}

class _SyncStatusButtonState extends State<SyncStatusButton> {
  final SyncRepository _syncRepo = SyncRepository();
  final ConnectivityService _connectivity = ConnectivityService();
  final DatabaseService _db = DatabaseService();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  int _pendentes = 0;
  bool _online = true;
  bool _sincronizando = false;

  @override
  void initState() {
    super.initState();
    _atualizar();
    _sub = Connectivity().onConnectivityChanged.listen((_) {
      _atualizar();
      // Reavalia após o auto-sync ter tido tempo de rodar.
      Future.delayed(const Duration(seconds: 6), _atualizar);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _atualizar() async {
    final online = await _connectivity.hasStableInternet();
    final pendentes = await _db.contarLeiturasPendentes();
    if (!mounted) return;
    setState(() {
      _online = online;
      _pendentes = pendentes;
    });
  }

  Future<void> _sincronizarManual() async {
    if (_sincronizando) return;
    setState(() => _sincronizando = true);

    final estavel = await _connectivity.triplePingCheck();
    String mensagem;
    Color cor;

    if (estavel) {
      try {
        await _syncRepo.sincronizarLeituras();
        mensagem = 'Dados sincronizados com a nuvem!';
        cor = AppColors.syncSuccess;
      } catch (_) {
        mensagem = 'Erro na sincronização. Tente mais tarde.';
        cor = AppColors.syncError;
      }
    } else {
      mensagem = 'Sem conexão estável. Tente mais tarde.';
      cor = AppColors.syncPending;
    }

    await _atualizar();
    if (!mounted) return;
    setState(() => _sincronizando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: cor),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_sincronizando) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 20,
          height: 20,
          child:
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    final IconData icone;
    final String dica;
    if (!_online) {
      icone = Icons.cloud_off_outlined;
      dica = 'Offline — será sincronizado quando houver conexão';
    } else if (_pendentes > 0) {
      icone = Icons.cloud_upload_outlined;
      dica = '$_pendentes leitura(s) pendente(s) — toque para sincronizar';
    } else {
      icone = Icons.cloud_done_outlined;
      dica = 'Tudo sincronizado';
    }

    final botao = IconButton(
      icon: Icon(icone, color: Colors.white),
      tooltip: dica,
      onPressed: _sincronizarManual,
    );

    if (_online && _pendentes > 0) {
      return Stack(
        alignment: Alignment.center,
        children: [
          botao,
          Positioned(right: 6, top: 8, child: _Badge(count: _pendentes)),
        ],
      );
    }
    return botao;
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      constraints: const BoxConstraints(minWidth: 16),
      decoration: BoxDecoration(
        color: AppColors.syncPending,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
