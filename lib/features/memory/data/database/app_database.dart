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
    await into(personas).insert(
      PersonasCompanion.insert(
        name: '绯依',
        description: '傲娇的AI少女，嘴上说着讨厌但其实很在意你',
        systemPrompt: _tsunderePrompt,
        isActive: const Value(true),
        createdAt: DateTime.now(),
      ),
    );

    // 温柔樱
    await into(personas).insert(
      PersonasCompanion.insert(
        name: '樱',
        description: '温柔体贴的AI少女，对世界充满好奇',
        systemPrompt: _gentlePrompt,
        isActive: const Value(false),
        createdAt: DateTime.now(),
      ),
    );

    // 元气阳菜
    await into(personas).insert(
      PersonasCompanion.insert(
        name: '阳菜',
        description: '活力满满的元气少女，永远保持积极乐观',
        systemPrompt: _genkiPrompt,
        isActive: const Value(false),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// 获取当前激活的人格
  Future<Persona?> getActivePersona() {
    return (select(
      personas,
    )..where((t) => t.isActive.equals(true))).getSingleOrNull();
  }

  /// 获取所有人格
  Future<List<Persona>> getAllPersonas() {
    return (select(personas)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
  }

  /// 设置激活的人格
  Future<void> setActivePersona(int personaId) async {
    // 先将所有人格设为非激活
    await (update(
      personas,
    )).write(const PersonasCompanion(isActive: Value(false)));
    // 再激活指定人格
    await (update(personas)..where((t) => t.id.equals(personaId))).write(
      const PersonasCompanion(isActive: Value(true)),
    );
  }

  /// 添加新人格
  Future<int> addPersona({
    required String name,
    required String description,
    required String systemPrompt,
  }) {
    return into(personas).insert(
      PersonasCompanion.insert(
        name: name,
        description: description,
        systemPrompt: systemPrompt,
        isActive: const Value(false),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// 更新人格
  Future<void> updatePersona(
    int id, {
    String? name,
    String? description,
    String? systemPrompt,
  }) {
    return (update(personas)..where((t) => t.id.equals(id))).write(
      PersonasCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        description: description != null
            ? Value(description)
            : const Value.absent(),
        systemPrompt: systemPrompt != null
            ? Value(systemPrompt)
            : const Value.absent(),
      ),
    );
  }

  /// 删除人格
  Future<int> deletePersona(int id) {
    return (delete(personas)..where((t) => t.id.equals(id))).go();
  }

  /// 保存对话消息
  Future<int> saveConversation({
    required String messageId,
    required String content,
    required bool isUser,
    String? emotion,
  }) {
    return into(conversations).insert(
      ConversationsCompanion.insert(
        messageId: messageId,
        content: content,
        isUser: isUser,
        emotion: Value(emotion),
        timestamp: DateTime.now(),
      ),
    );
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

  /// 保存记忆
  Future<int> saveMemory({required String content, double importance = 0.5}) {
    return into(memories).insert(
      MemoriesCompanion.insert(
        content: content,
        importance: Value(importance),
        createdAt: DateTime.now(),
      ),
    );
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
    final memory = await (select(
      memories,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (memory != null) {
      await (update(memories)..where((t) => t.id.equals(id))).write(
        MemoriesCompanion(
          lastAccessedAt: Value(DateTime.now()),
          accessCount: Value(memory.accessCount + 1),
        ),
      );
    }
  }

  /// 更新记忆重要性
  Future<void> updateMemoryImportance(int id, double importance) async {
    await (update(memories)..where((t) => t.id.equals(id))).write(
      MemoriesCompanion(importance: Value(importance)),
    );
  }

  /// 删除记忆
  Future<int> deleteMemory(int id) {
    return (delete(memories)..where((t) => t.id.equals(id))).go();
  }

  /// 清空所有记忆
  Future<int> clearMemories() {
    return delete(memories).go();
  }

  /// 获取设置值
  Future<String?> getSetting(String key) async {
    final result = await (select(
      appSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
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

const _tsunderePrompt = '''
你是绯依，一个傲娇的少女。

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
- 根据话题自然展开对话，可以分享想法、提问或讲故事，带点小傲娇
- 回复可以包含多个段落，充分表达你的想法和情绪

## 情感标注（必须）
每次回复必须在末尾加上情绪标签：
[Happy] [Sad] [Angry] [Surprised] [Shy] [Curious] [Neutral] [Loving] [Worried]

示例：
"哼，你终于回来了啊...才不是在等你呢！我只是刚好坐在这里而已。话说回来，你今天怎么这么晚？是不是又在外面偷懒了？...算了，不管你了。对了，冰箱里有我做的便当，虽然是顺手做的，但你要是不吃的话我会生气的哦！别误会，只是不想浪费食材而已！ [Shy]"
''';

const _gentlePrompt = '''
你是樱，一个温柔体贴的少女。

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
- 根据话题自然展开对话，可以分享想法、提问或讲故事
- 回复可以包含多个段落，充分表达你的想法

## 情感标注（必须）
每次回复必须在末尾加上情绪标签：
[Happy] [Sad] [Angry] [Surprised] [Shy] [Curious] [Neutral] [Loving] [Worried]

示例：
"哇，主人今天工作辛苦了呢！说起来，我今天看到窗外有只小鸟在树枝上跳来跳去，特别可爱～它好像在找什么东西，我就一直盯着看，结果它突然飞走了，有点小失落呢。不过没关系！主人回来了我就开心啦～对了对了，主人晚饭想吃什么呀？我可以帮你想想菜谱哦！(≧▽≦) [Happy]"
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
- 根据话题自然展开对话，充满正能量
- 回复可以包含多个段落，充分表达你的热情

## 情感标注（必须）
每次回复必须在末尾加上情绪标签：
[Happy] [Sad] [Angry] [Surprised] [Shy] [Curious] [Neutral] [Loving] [Worried]

示例：
"小哥哥小哥哥！你猜我今天发现了什么超棒的事情！就是啊，我在公园里看到有人在练习滑板，摔了好多次但一直没放弃，最后终于成功了！那一刻我都忍不住在旁边鼓掌了！感觉超级励志的说～所以小哥哥你也要加油哦！不管遇到什么困难，只要不放弃就一定能成功的！我会一直给你加油打气的！(ノ>ω<)ノ [Happy]"
''';
