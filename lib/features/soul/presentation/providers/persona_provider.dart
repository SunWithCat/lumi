import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumi/features/memory/presentation/providers/memory_provider.dart';
import 'package:lumi/features/soul/data/persona_repository.dart';
import 'package:lumi/features/soul/domain/entities/persona_config.dart';

/// PersonaRepository Provider - 复用 databaseProvider 避免数据库锁定
final personaRepositoryProvider = Provider<PersonaRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PersonaRepository(db);
});

class PersonaState {
  final PersonaConfig current;
  final List<PersonaConfig> all;

  const PersonaState({required this.current, required this.all});

  PersonaState copyWith({PersonaConfig? current, List<PersonaConfig>? all}) {
    return PersonaState(current: current ?? this.current, all: all ?? this.all);
  }
}

final personaProvider =
    StateNotifierProvider<PersonaNotifier, AsyncValue<PersonaState>>((ref) {
      final repo = ref.watch(personaRepositoryProvider);
      return PersonaNotifier(repo);
    });

final currentPersonaProvider = Provider<AsyncValue<PersonaConfig>>((ref) {
  return ref.watch(personaProvider).whenData((state) => state.current);
});

final allPersonasProvider = Provider<AsyncValue<List<PersonaConfig>>>((ref) {
  return ref.watch(personaProvider).whenData((state) => state.all);
});

class PersonaNotifier extends StateNotifier<AsyncValue<PersonaState>> {
  final PersonaRepository _repo;

  PersonaNotifier(this._repo) : super(const AsyncValue.loading()) {
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final current = await _repo.getCurrentPersona();
      final all = await _repo.getAllPersonas();
      state = AsyncValue.data(PersonaState(current: current, all: all));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 切换人格（通过 ID）
  Future<void> setPersonaById(int personaId) async {
    try {
      await _repo.setActivePersona(personaId);
      await _loadAll();
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
    await _loadAll();
    return id;
  }

  /// 更新人格（通过 ID）
  Future<void> updatePersonaById(
    int id, {
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
    await _loadAll();
  }

  /// 创建自定义人格（基于当前人格，但创建新的而不是修改原有）
  Future<void> createCustomPersona({
    required String name,
    required String bio,
    required String userTitle,
  }) async {
    final current = state.valueOrNull?.current;
    if (current == null) return;

    // 创建新的人格配置，不带 customSystemPrompt，强制根据属性生成
    final newPersona = PersonaConfig(
      id: '', // 新人格，ID 由数据库生成
      name: name,
      age: current.age,
      bio: bio,
      traits: current.traits,
      speakingStyle: current.speakingStyle,
      userTitle: userTitle,
      baselineEmotion: current.baselineEmotion,
      emotionalSensitivity: current.emotionalSensitivity,
      customSystemPrompt: null, // 清空，强制使用属性生成
      isActive: false,
    );

    // 添加新人格到数据库
    final newId = await _repo.addPersona(newPersona);

    // 激活新人格
    await setPersonaById(newId);
  }

  /// 更新已有人格（用于编辑自定义人格，不是预设）
  Future<void> updatePersona({
    String? name,
    String? bio,
    String? userTitle,
  }) async {
    final current = state.valueOrNull?.current;
    if (current == null) return;

    final personaId = int.tryParse(current.id);
    if (personaId != null) {
      // 创建一个没有 customSystemPrompt 的副本，强制重新生成 systemPrompt
      final updated = PersonaConfig(
        id: current.id,
        name: name ?? current.name,
        age: current.age,
        bio: bio ?? current.bio,
        traits: current.traits,
        speakingStyle: current.speakingStyle,
        userTitle: userTitle ?? current.userTitle,
        baselineEmotion: current.baselineEmotion,
        emotionalSensitivity: current.emotionalSensitivity,
        customSystemPrompt: null, // 清空，强制使用属性生成
        isActive: current.isActive,
      );

      await _repo.updatePersona(
        personaId,
        name: name,
        description: bio,
        systemPrompt: updated.systemPrompt, // 现在会根据新属性生成
      );
      await _loadAll();
    }
  }

  /// 删除人格
  Future<void> deletePersona(int id) async {
    await _repo.deletePersona(id);
    await _loadAll();
  }

  /// 刷新
  Future<void> refresh() async {
    await _loadAll();
  }
}
