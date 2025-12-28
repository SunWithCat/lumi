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

@DriftDatabase(tables: [Conversations, Memories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'waifu.db'));
    return NativeDatabase.createInBackground(file);
  });
}
