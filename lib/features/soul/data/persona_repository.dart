import 'package:lumi/features/memory/data/database/app_database.dart';
import 'package:lumi/features/soul/domain/entities/persona_config.dart';

/// 人格配置存储 - 基于 Drift 数据库
class PersonaRepository {
  final AppDatabase _db;

  PersonaRepository(this._db);

  /// 获取当前激活的人格配置
  Future<PersonaConfig> getCurrentPersona() async {
    final persona = await _db.getActivePersona();
    if (persona == null) {
      // 如果没有激活的人格，返回默认
      return PersonaConfig.sakura;
    }
    return _mapToConfig(persona);
  }

  /// 获取所有人格配置
  Future<List<PersonaConfig>> getAllPersonas() async {
    final personas = await _db.getAllPersonas();
    return personas.map(_mapToConfig).toList();
  }

  /// 设置激活的人格
  Future<void> setActivePersona(int personaId) async {
    await _db.setActivePersona(personaId);
  }

  /// 添加新人格
  Future<int> addPersona(PersonaConfig config) async {
    return await _db.addPersona(
      name: config.name,
      description: config.bio,
      systemPrompt: config.systemPrompt,
    );
  }

  /// 更新人格
  Future<void> updatePersona(
    int id, {
    String? name,
    String? description,
    String? systemPrompt,
  }) async {
    await _db.updatePersona(
      id,
      name: name,
      description: description,
      systemPrompt: systemPrompt,
    );
  }

  /// 删除人格
  Future<void> deletePersona(int id) async {
    await _db.deletePersona(id);
  }

  /// 将 Drift Persona 映射为 PersonaConfig
  PersonaConfig _mapToConfig(Persona persona) {
    return PersonaConfig(
      id: persona.id.toString(),
      name: persona.name,
      age: '18岁', // 数据库暂不存储
      bio: persona.description,
      traits: _extractTraits(persona.systemPrompt),
      speakingStyle: _extractSpeakingStyle(persona.systemPrompt),
      userTitle: _extractUserTitle(persona.systemPrompt),
      customSystemPrompt: persona.systemPrompt,
      isActive: persona.isActive,
    );
  }

  /// 从 systemPrompt 提取性格特点 (仅对预设有意义，自定义直接返回)
  List<String> _extractTraits(String prompt) {
    final regex = RegExp(r'## 核心人格\n((?:- .+\n?)+)');
    final match = regex.firstMatch(prompt);
    if (match != null) {
      return match
          .group(1)!
          .split('\n')
          .where((line) => line.startsWith('- '))
          .map((line) => line.substring(2).trim())
          .toList();
    }
    return ['自定义'];
  }

  /// 从 systemPrompt 提取说话风格
  String _extractSpeakingStyle(String prompt) {
    if (prompt.contains('傲娇')) return '经常说“才不是呢”、“哼”';
    if (prompt.contains('元气')) return '语气活泼，经常用“！”';
    return '自定义语气';
  }

  /// 从 systemPrompt 提取用户称呼
  String _extractUserTitle(String prompt) {
    final regex = RegExp(r'称呼用户为“([^"]+)”');
    final match = regex.firstMatch(prompt);
    return match?.group(1) ?? '你';
  }
}
