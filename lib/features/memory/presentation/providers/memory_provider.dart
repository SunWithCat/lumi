import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumi/features/memory/data/database/app_database.dart';
import 'package:lumi/features/memory/data/memory_repository.dart';

/// 数据库 Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// 记忆仓库 Provider
final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return MemoryRepository(db);
});
