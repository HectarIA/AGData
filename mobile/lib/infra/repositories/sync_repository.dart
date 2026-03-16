import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isar/isar.dart';
import '../services/connectivity_service.dart';
import '../../features/diagnostico/data/models/leitura_model.dart';
import '../../features/diagnostico/data/datasources/database_service.dart';

class SyncRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConnectivityService _connectivity = ConnectivityService();

  Future<void> sincronizarLeituras() async {
    if (!await _connectivity.triplePingCheck()) return;

    final leiturasPendentes = await DatabaseService.isar.leituraModels
        .filter()
        .sincronizadoEqualTo(false)
        .findAll();

    if (leiturasPendentes.isEmpty) return;

    final batch = _firestore.batch();
    final collection = _firestore.collection('diagnosticos');

    for (var leitura in leiturasPendentes) {
      final docRef = collection.doc(); 
      batch.set(docRef, {
        'doenca': leitura.resultadoIA,
        'confianca': leitura.confianca,
        'data': leitura.dataHora.toIso8601String(),
        'latitude': leitura.latitude,
        'longitude': leitura.longitude,
        'talhao': leitura.talhao,
        'sincronizadoEm': FieldValue.serverTimestamp(),
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
    } catch (e) {
      rethrow;
    }
  }
}