import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumi/core/theme/app_theme.dart';
import 'package:lumi/features/memory/domain/memory_compactor.dart';
import 'package:lumi/features/memory/presentation/providers/memory_provider.dart';
import 'package:toastification/toastification.dart';

/// 记忆管理页面
///
/// 功能：
/// 1. 查看所有记忆
/// 2. 删除单条记忆
/// 3. 执行记忆压缩
/// 4. 查看记忆统计
class MemoryManagementPage extends ConsumerStatefulWidget {
  const MemoryManagementPage({super.key});

  @override
  ConsumerState<MemoryManagementPage> createState() =>
      _MemoryManagementPageState();
}

class _MemoryManagementPageState extends ConsumerState<MemoryManagementPage> {
  List<MemoryItem> _memories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    setState(() => _isLoading = true);

    final repo = ref.read(memoryRepositoryProvider);
    final memories = await repo.getAllMemories();

    // 按重要性排序
    memories.sort((a, b) => b.importance.compareTo(a.importance));

    setState(() {
      _memories = memories;
      _isLoading = false;
    });
  }

  Future<void> _runCompaction({bool dryRun = true}) async {
    setState(() => _isLoading = true);

    final repo = ref.read(memoryRepositoryProvider);
    final result = await repo.compactMemories(dryRun: dryRun);

    setState(() => _isLoading = false);

    if (dryRun) {
      _showCompactionPreview(result);
    } else {
      _showSnackBar('压缩完成，删除了 ${result.toRemoveCount} 条记忆');
      _loadMemories();
    }
  }

  void _showCompactionPreview(CompactionResult result) {
    final colorScheme = context.colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.auto_fix_high_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '压缩预览',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildCompactStatCard(
                  '总记忆',
                  '${result.totalMemories}',
                  colorScheme.primary,
                ),
                const SizedBox(width: 10),
                _buildCompactStatCard(
                  '可删除',
                  '${result.toRemoveCount}',
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '预计节省空间',
                    style: TextStyle(fontSize: 13, color: Colors.green),
                  ),
                  Text(
                    '${(result.estimatedSavings * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            if (result.mergeResults.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.layers_rounded, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    '相似记忆合并建议',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    children: result.mergeResults
                        .take(5)
                        .map((merge) => _buildMergeItem(merge))
                        .toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消', style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _runCompaction(dryRun: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('执行压缩'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMergeItem(MemoryMergeResult merge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 14,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _truncate(merge.keep.content, 50),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '将合并 ${merge.remove.length} 条相似内容',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  void _showSnackBar(String message) {
    toastification.dismissAll();
    toastification.show(
      context: context,
      title: Text(message),
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      primaryColor: context.colorScheme.primary,
      icon: Icon(
        Icons.check_circle_rounded,
        color: context.colorScheme.primary,
      ),
      autoCloseDuration: const Duration(seconds: 2),
      alignment: Alignment.bottomCenter,
      showProgressBar: false,
    );
  }

  Future<void> _clearAllMemories() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '清空所有记忆',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        content: const Text(
          '确定要清空所有记忆吗？此操作不可恢复！',
          style: TextStyle(color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('取消', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(databaseProvider);
      await db.clearMemories();
      _showSnackBar('所有记忆已清空');
      _loadMemories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('记忆管理', style: TextStyle(color: Color(0xFF333333))),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.primary),
          onPressed: () => context.pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colorScheme.primary),
            onSelected: (value) {
              switch (value) {
                case 'compact':
                  _runCompaction(dryRun: true);
                  break;
                case 'clear':
                  _clearAllMemories();
                  break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'compact',
                child: Row(
                  children: [
                    Icon(Icons.compress_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('压缩记忆'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_forever_rounded,
                      size: 20,
                      color: Colors.redAccent,
                    ),
                    SizedBox(width: 12),
                    Text('清空所有', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : _memories.isEmpty
          ? _buildEmptyState()
          : _buildMemoryList(),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = context.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.memory_rounded, size: 64, color: colorScheme.secondary),
          const SizedBox(height: 16),
          Text(
            '还没有记忆',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            '和 AI 聊天时会自动记住重要信息',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryList() {
    return Column(
      children: [
        // 统计信息
        _buildStatsCard(),
        // 记忆列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _memories.length,
            itemBuilder: (context, index) => _buildMemoryCard(_memories[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    final lumiColors = context.lumiColors;
    final totalCount = _memories.length;
    final avgImportance = _memories.isEmpty
        ? 0.0
        : _memories.fold<double>(0, (sum, m) => sum + m.importance) /
              totalCount;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            lumiColors.primaryGradientStart,
            lumiColors.primaryGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: lumiColors.shadowColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('总记忆', '$totalCount'),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStatItem('平均重要性', avgImportance.toStringAsFixed(2)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryCard(MemoryItem memory) {
    final importanceColor = _getImportanceColor(memory.importance);

    return Dismissible(
      key: Key('memory_${memory.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '删除记忆',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
            content: const Text(
              '确定要删除这条记忆吗？',
              style: TextStyle(color: Color(0xFF666666)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('取消', style: TextStyle(color: Colors.grey[600])),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        final db = ref.read(databaseProvider);
        await db.deleteMemory(memory.id);
        setState(() => _memories.removeWhere((m) => m.id == memory.id));
        _showSnackBar('记忆已删除');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: importanceColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '重要性: ${(memory.importance * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: importanceColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(memory.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              memory.content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF333333),
                height: 1.4,
              ),
            ),
            if (memory.accessCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '访问次数: ${memory.accessCount}',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getImportanceColor(double importance) {
    if (importance >= 0.7) return Colors.green;
    if (importance >= 0.4) return Colors.orange;
    return Colors.grey;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '今天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
