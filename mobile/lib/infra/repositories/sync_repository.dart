import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart';
import '../services/connectivity_service.dart';
import '../../features/diagnostico/data/models/leitura_model.dart';
import '../../features/diagnostico/data/datasources/database_service.dart';

class SyncRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConnectivityService _connectivity = ConnectivityService();

  Future<void> sincronizarLeituras() async {
    if (!await _connectivity.triplePingCheck()) {
      debugPrint('⚠️ [SYNC] Conexão instável. Dados mantidos no backup local.');
      return;
    }

    final leiturasPendentes = await DatabaseService.isar.leituraModels
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
        'confianca': leitura.confianca,
        'data_local': leitura.dataHora.toIso8601String(),
        'latitude': leitura.latitude,
        'longitude': leitura.longitude,
        'sincronizado_em': FieldValue.serverTimestamp(),
      });
    }

    try {
      await batch.commit();

      await DatabaseService.isar.writeTxn(() async {
        for (var leitura in leiturasPendentes) {
          leitura.sincronizado = true;
          await DatabaseService.isar.leituraModels.put(leitura);
        }
      });
      
      await _limparCacheAntigo();
      
    } catch (e) {
      debugPrint('❌ [SYNC ERROR] Falha no commit. Backup local preservado.');
    }
  }

  Future<void> _limparCacheAntigo() async {
    final seteDiasAtras = DateTime.now().subtract(const Duration(days: 7));
    
    await DatabaseService.isar.writeTxn(() async {
      final antigos = await DatabaseService.isar.leituraModels
          .filter()
          .sincronizadoEqualTo(true)
          .dataHoraLessThan(seteDiasAtras)
          .findAll();

      if (antigos.isNotEmpty) {
        final ids = antigos.map((e) => e.id).toList();
        await DatabaseService.isar.leituraModels.deleteAll(ids);
        debugPrint('♻️ [CACHE] ${ids.length} registros antigos removidos.');
      }
    });
  }
}