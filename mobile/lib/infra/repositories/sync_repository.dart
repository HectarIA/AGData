import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart';
import '../services/connectivity_service.dart';
import '../../features/diagnostico/data/models/leitura_model.dart';
import '../../core/di/injection_container.dart';
import '../../core/errors/exception.dart'; 

class SyncRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConnectivityService _connectivity = sl<ConnectivityService>();
  final Isar _isar = sl<Isar>();
  
  bool _isSyncing = false; 

  Future<void> sincronizarLeituras() async {
    if (_isSyncing) {
      debugPrint('[SYNC] Sincronização já em andamento. Ignorando chamada duplicada.');
      return;
    }
    
    _isSyncing = true;
    final stopwatch = Stopwatch()..start();
    
    try {
      if (!await _connectivity.triplePingCheck()) return;

      final leiturasPendentes = await _isar.leituraModels
          .filter()
          .sincronizadoEqualTo(false)
          .sortByDataHoraDesc() 
          .findAll();

      if (leiturasPendentes.isEmpty) {
        await _limparCacheAntigo();
        return;
      }

      final batch = _firestore.batch();

      for (var leitura in leiturasPendentes) {
        final talhaoId = leitura.talhao.replaceAll(' ', '_').toLowerCase();
        final docRef = _firestore
            .collection('talhoes')
            .doc(talhaoId)
            .collection('diagnosticos')
            .doc(); 

        batch.set(docRef, {
          'doenca': leitura.resultadoIA,
          'confianca': double.parse(leitura.confianca.toStringAsFixed(2)),
          'data_local': leitura.dataHora.toIso8601String(),
          'latitude': leitura.latitude,
          'longitude': leitura.longitude,
          'sincronizado_em': FieldValue.serverTimestamp(),
          'audit': {
            'app_version': '1.0.0+1',
            'platform': defaultTargetPlatform.name,
            'local_id': leitura.id, 
          }
        });
      }

      try {
        await batch.commit();
        stopwatch.stop();
        debugPrint('🚀 [SYNC] ${leiturasPendentes.length} laudos enviados com sucesso em ${stopwatch.elapsedMilliseconds}ms');
      } on FirebaseException catch (e) {
        throw ServerException('Falha na comunicação com o Firebase: ${e.code}');
      }

      try {
        await _isar.writeTxn(() async {
          for (var leitura in leiturasPendentes) {
            leitura.sincronizado = true;
            await _isar.leituraModels.put(leitura);
          }
        });
      } catch (e) {
        throw CacheException('Erro ao atualizar backup local no Isar');
      }
      
      await _limparCacheAntigo();
      
    } catch (e) {
      debugPrint('❌ [SYNC ERROR] $e');
      rethrow; 
    } finally {
      _isSyncing = false; 
    }
  }

  Future<void> _limparCacheAntigo() async {
    final seteDiasAtras = DateTime.now().subtract(const Duration(days: 7));
    
    try {
      await _isar.writeTxn(() async {
        final antigos = await _isar.leituraModels
            .filter()
            .sincronizadoEqualTo(true)
            .dataHoraLessThan(seteDiasAtras)
            .findAll();

        if (antigos.isNotEmpty) {
          final ids = antigos.map((e) => e.id).toList();
          await _isar.leituraModels.deleteAll(ids);
          debugPrint('♻️ [CACHE] Registros antigos (7+ dias) removidos com sucesso.');
        }
      });
    } catch (e) {
      debugPrint('⚠️ [CACHE ERROR] Falha ao limpar registros antigos: $e');
    }
  }
}