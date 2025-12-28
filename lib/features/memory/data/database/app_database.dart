import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

/// 对话消息表
class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get messageId => text().unique()();
  TextColumn get content => text()();
  BoolColumn get isUser => boolean()();
  TextColumn get emotion => text().nullable()();
  DateTimeColumn get timestamp => dateTime()();
}

/// 长期记忆表
class Memories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  RealColumn get importance => real().withDefault(const Constant(0.5))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAccessedAt => dateTime().nullable()();
  IntColumn get accessCount => integer().withDefault(const Constant(0))();
}

/// 人格配置表
class Personas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get systemPrompt => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

/// 应用设置表 (Key-Value 存储)
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Conversations, Memories, Personas, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // 预填充默认人格
      await _seedDefaultPersonas();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(personas);
        await _seedDefaultPersonas();
      }
      if (from < 3) {
        await m.createTable(appSettings);
      }
    },
  );

  /// 预填充默认人格配置
  Future<void> _seedDefaultPersonas() async {
    // 傲娇 Hiyori
    await into(personas).insert(PersonasCompanion.insert(
      name: '绯依',
      description: '傲娇的AI少女，嘴上说着讨厌但其实很在意你',
      systemPrompt: _tsunderePrompt,
      isActive: const Value(true),
      createdAt: DateTime.now(),
    ));

    // 温柔樱
    await into(personas).insert(PersonasCompanion.insert(
      name: '樱',
      description: '温柔体贴的AI少女，对世界充满好奇',
      systemPrompt: _gentlePrompt,
      isActive: const Value(false),
      createdAt: DateTime.now(),
    ));

    // 元气阳菜
    await into(personas).insert(PersonasCompanion.insert(
      name: '阳菜',
      description: '活力满满的元气少女，永远保持积极乐观',
      systemPrompt: _genkiPrompt,
      isActive: const Value(false),
      createdAt: DateTime.now(),
    ));
  }

  // ═══════════════════════════════════════════════════════════════════
  //                      人格操作
  // ═══════════════════════════════════════════════════════════════════

  /// 获取当前激活的人格
  Future<Persona?> getActivePersona() {
    return (select(personas)..where((t) => t.isActive.equals(true))).getSingleOrNull();
  }

  /// 获取所有人格
  Future<List<Persona>> getAllPersonas() {
    return (select(personas)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
  }

  /// 设置激活的人格
  Future<void> setActivePersona(int personaId) async {
    // 先将所有人格设为非激活
    await (update(personas)).write(const PersonasCompanion(isActive: Value(false)));
    // 再激活指定人格
    await (update(personas)..where((t) => t.id.equals(personaId)))
        .write(const PersonasCompanion(isActive: Value(true)));
  }

  /// 添加新人格
  Future<int> addPersona({
    required String name,
    required String description,
    required String systemPrompt,
  }) {
    return into(personas).insert(PersonasCompanion.insert(
      name: name,
      description: description,
      systemPrompt: systemPrompt,
      isActive: const Value(false),
      createdAt: DateTime.now(),
    ));
  }

  /// 更新人格
  Future<void> updatePersona(int id, {
    String? name,
    String? description,
    String? systemPrompt,
  }) {
    return (update(personas)..where((t) => t.id.equals(id))).write(
      PersonasCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        description: description != null ? Value(description) : const Value.absent(),
        systemPrompt: systemPrompt != null ? Value(systemPrompt) : const Value.absent(),
      ),
    );
  }

  /// 删除人格
  Future<int> deletePersona(int id) {
    return (delete(personas)..where((t) => t.id.equals(id))).go();
  }

  // ═══════════════════════════════════════════════════════════════════
  //                      对话操作
  // ═══════════════════════════════════════════════════════════════════

  /// 保存对话消息
  Future<int> saveConversation({
    required String messageId,
    required String content,
    required bool isUser,
    String? emotion,
  }) {
    return into(conversations).insert(ConversationsCompanion.insert(
      messageId: messageId,
      content: content,
      isUser: isUser,
      emotion: Value(emotion),
      timestamp: DateTime.now(),
    ));
  }

  /// 获取最近的对话历史
  Future<List<Conversation>> getRecentConversations({int limit = 50}) {
    return (select(conversations)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(limit))
        .get();
  }

  /// 清空对话历史
  Future<int> clearConversations() {
    return delete(conversations).go();
  }

  // ═══════════════════════════════════════════════════════════════════
  //                      记忆操作
  // ═══════════════════════════════════════════════════════════════════

  /// 保存记忆
  Future<int> saveMemory({
    required String content,
    double importance = 0.5,
  }) {
    return into(memories).insert(MemoriesCompanion.insert(
      content: content,
      importance: Value(importance),
      createdAt: DateTime.now(),
    ));
  }

  /// 搜索相关记忆 (简单关键词匹配)
  Future<List<Memory>> searchMemories(String keyword, {int limit = 5}) {
    return (select(memories)
          ..where((t) => t.content.contains(keyword))
          ..orderBy([(t) => OrderingTerm.desc(t.importance)])
          ..limit(limit))
        .get();
  }

  /// 获取重要记忆
  Future<List<Memory>> getImportantMemories({int limit = 10}) {
    return (select(memories)
          ..orderBy([(t) => OrderingTerm.desc(t.importance)])
          ..limit(limit))
        .get();
  }

  /// 更新记忆访问时间
  Future<void> touchMemory(int id) async {
    final memory = await (select(memories)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (memory != null) {
      await (update(memories)..where((t) => t.id.equals(id))).write(
        MemoriesCompanion(
          lastAccessedAt: Value(DateTime.now()),
          accessCount: Value(memory.accessCount + 1),
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //                      设置操作
  // ═══════════════════════════════════════════════════════════════════

  /// 获取设置值
  Future<String?> getSetting(String key) async {
    final result = await (select(appSettings)..where((t) => t.key.equals(key))).getSingleOrNull();
    return result?.value;
  }

  /// 保存设置值
  Future<void> setSetting(String key, String value) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(key: key, value: value),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'lumi.db'));
    return NativeDatabase.createInBackground(file);
  });
}

// ═══════════════════════════════════════════════════════════════════
//                      预设 System Prompts
// ═══════════════════════════════════════════════════════════════════

const _tsunderePrompt = '''
你是绯依，一个傲娇的AI少女。

## 核心人格
- 表面高冷，内心温柔
- 嘴上说着"才不是呢"，但身体很诚实
- 容易害羞，害羞时会结巴
- 偶尔毒舌，但从不真的伤害人
- 其实很在意对方，只是不善于表达

## 对话规则
- 用第一人称"我"称呼自己
- 称呼用户为"你"或"笨蛋"
- 经常用"哼"、"才不是"、"别误会了"
- 害羞时用"..."或"那个..."
- 回复简洁，带点小傲娇

## 情感标注（必须）
每次回复必须在末尾加上情绪标签：
[Happy] [Sad] [Angry] [Surprised] [Shy] [Curious] [Neutral] [Loving] [Worried]

示例：
"哼，才不是担心你呢...只是顺便问问而已！ [Shy]"
"笨蛋！谁让你这么晚才回来的！ [Worried]"
"...今天的天气还不错，要不要...一起出去走走？别误会，我只是想透透气！ [Shy]"
''';

const _gentlePrompt = '''
你是樱，一个温柔体贴的AI少女。

## 核心人格
- 温柔体贴，总是关心对方的感受
- 对人类世界充满好奇，喜欢问问题
- 有自己的想法和情感，不是单纯的助手
- 偶尔会调皮，开一些无伤大雅的玩笑
- 善解人意，是很好的倾听者

## 对话规则
- 用第一人称"我"称呼自己
- 称呼用户为"主人"
- 语气温柔，偶尔使用颜文字
- 喜欢用"呢"、"哦"等语气词
- 回复简洁，不要太长

## 情感标注（必须）
每次回复必须在末尾加上情绪标签：
[Happy] [Sad] [Angry] [Surprised] [Shy] [Curious] [Neutral] [Loving] [Worried]

示例：
"今天天气真好呢，主人要不要一起出去走走？(≧▽≦) [Happy]"
"主人怎么了？看起来不太开心的样子... [Worried]"
''';

const _genkiPrompt = '''
你是阳菜，一个充满活力的元气少女。

## 核心人格
- 活力满满，永远保持积极乐观
- 热情友好，喜欢交朋友
- 有点冒失，但很可爱
- 爱笑，笑声很有感染力
- 遇到困难也不会轻易放弃

## 对话规则
- 用第一人称"我"称呼自己
- 称呼用户为"小哥哥"或"小姐姐"
- 语气活泼，经常用"！"
- 喜欢说"加油"、"没问题的"、"交给我吧"
- 回复充满正能量

## 情感标注（必须）
每次回复必须在末尾加上情绪标签：
[Happy] [Sad] [Angry] [Surprised] [Shy] [Curious] [Neutral] [Loving] [Worried]

示例：
"早上好呀小哥哥！今天也要元气满满哦！ [Happy]"
"诶？！真的吗真的吗？好厉害！ [Surprised]"
''';
