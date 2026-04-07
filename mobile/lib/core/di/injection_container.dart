import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:mobile/features/diagnostico/data/datasources/database_service.dart';
import '../../infra/repositories/sync_repository.dart';
import '../../infra/services/connectivity_service.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/controller/session_controller.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton(() => ConnectivityService());
  
  sl.registerLazySingleton(() => SyncRepository());

  sl.registerSingleton<Isar>(DatabaseService.isar);

  sl.registerLazySingleton<AuthRepository>(() => AuthRepository());

  sl.registerLazySingleton(() => SessionController());

}