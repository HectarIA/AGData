import 'dart:io';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../repositories/sync_repository.dart';
import '../../core/di/injection_container.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void configurarOuvinteDeSincronizacao() {
    _subscription?.cancel(); 
    
    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      final temInternet = results.any((result) => result != ConnectivityResult.none);
      
      if (temInternet) {
        debugPrint('🌐 [NETWORK] Mudança de estado: Conectado. Validando estabilidade...');
        
        await Future.delayed(const Duration(seconds: 2));
        
        if (await triplePingCheck()) {
          debugPrint('🚀 [NETWORK] Estabilidade confirmada. Disparando Sync Automático.');
          sl<SyncRepository>().sincronizarLeituras();
        }
      } else {
        debugPrint('🚫 [NETWORK] Dispositivo Offline.');
      }
    });
  }

  Future<bool> hasStableInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    }
  }

  Future<bool> triplePingCheck() async {
    int sucessos = 0;
    for (int i = 0; i < 3; i++) {
      if (await hasStableInternet()) sucessos++;
      if (i < 2) await Future.delayed(const Duration(milliseconds: 800));
    }
    return sucessos >= 2; 
  }

  void dispose() {
    _subscription?.cancel();
  }
}