import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waifu/features/memory/data/database/app_database.dart';
import 'package:waifu/features/soul/data/persona_repository.dart';
import 'package:waifu/features/soul/domain/entities/persona_config.dart';

/// AppDatabase Provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// PersonaRepository Provider
final personaRepositoryProvider = Provider<PersonaRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PersonaRepository(db);
});

/// 所有人格列表 Provider
final allPersonasProvider = FutureProvider<List<PersonaConfig>>((ref) async {
  final repo = ref.watch(personaRepositoryProvider);
  return repo.getAllPersonas();
});

/// 当前人格配置 Provider
final currentPersonaProvider = StateNotifierProvider<PersonaNotifier, AsyncValue<PersonaConfig>>((ref) {
  final repo = ref.watch(personaRepositoryProvider);
  return PersonaNotifier(repo, ref);
});

class PersonaNotifier extends StateNotifier<AsyncValue<PersonaConfig>> {
  final PersonaRepository _repo;
  final Ref _ref;

  PersonaNotifier(this._repo, this._ref) : super(const AsyncValue.loading()) {
    _loadCurrentPersona();
  }

  Future<void> _loadCurrentPersona() async {
    try {
      final persona = await _repo.getCurrentPersona();
      state = AsyncValue.data(persona);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 切换人格（通过 ID）
  Future<void> setPersonaById(int personaId) async {
    try {
      await _repo.setActivePersona(personaId);
      await _loadCurrentPersona();
      // 刷新人格列表
      _ref.invalidate(allPersonasProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 切换人格（通过 PersonaConfig）
  Future<void> setPersona(PersonaConfig config) async {
    try {
      final personaId = int.tryParse(config.id);
      if (personaId != null) {
        await setPersonaById(personaId);
      } else {
        // 预设人格，先添加到数据库再激活
        final newId = await addPersona(config);
        await setPersonaById(newId);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 添加新人格
  Future<int> addPersona(PersonaConfig config) async {
    final id = await _repo.addPersona(config);
    _ref.invalidate(allPersonasProvider);
    return id;
  }

  /// 更新人格（通过 ID）
  Future<void> updatePersonaById(int id, {
    String? name,
    String? description,
    String? systemPrompt,
  }) async {
    await _repo.updatePersona(
      id,
      name: name,
      description: description,
      systemPrompt: systemPrompt,
    );
    await _loadCurrentPersona();
    _ref.invalidate(allPersonasProvider);
  }

  /// 更新当前人格
  Future<void> updatePersona({
    String? name,
    String? bio,
    String? userTitle,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    final personaId = int.tryParse(current.id);
    if (personaId != null) {
      // 生成新的 systemPrompt
      final updated = current.copyWith(
        name: name,
        bio: bio,
        userTitle: userTitle,
      );
      await _repo.updatePersona(
        personaId,
        name: name,
        description: bio,
        systemPrompt: updated.systemPrompt,
      );
      await _loadCurrentPersona();
      _ref.invalidate(allPersonasProvider);
    }
  }

  /// 删除人格
  Future<void> deletePersona(int id) async {
    await _repo.deletePersona(id);
    _ref.invalidate(allPersonasProvider);
  }

  /// 刷新
  Future<void> refresh() async {
    await _loadCurrentPersona();
  }
}
