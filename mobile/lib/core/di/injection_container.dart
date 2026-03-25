import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:mobile/features/diagnostico/data/datasources/database_service.dart';
import '../../infra/repositories/sync_repository.dart';
import '../../infra/services/connectivity_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton(() => ConnectivityService());
  
  sl.registerLazySingleton(() => SyncRepository());

  sl.registerSingleton<Isar>(DatabaseService.isar);
}