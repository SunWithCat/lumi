/// 记忆压缩器
/// 
/// 负责管理记忆的生命周期，包括：
/// 1. 相似记忆合并 - 避免冗余
/// 2. 记忆衰减 - 长期未访问的记忆降低重要性
/// 3. 记忆清理 - 删除低重要性的旧记忆
/// 
/// ## 为什么需要记忆压缩？
/// 
/// 随着对话增多，记忆库会不断膨胀：
/// - "用户喜欢猫"
/// - "用户说他喜欢猫咪"
/// - "用户提到喜欢猫"
/// 
/// 这些本质上是同一条信息，应该合并为一条。
/// 
/// ## 压缩策略
/// 
/// ```
/// ┌─────────────────────────────────────────────────────────────┐
/// │                    记忆压缩流程                              │
/// ├─────────────────────────────────────────────────────────────┤
/// │                                                              │
/// │  原始记忆库:                                                 │
/// │  ┌─────────────────────────────────────────────────────┐    │
/// │  │ 1. "用户喜欢猫" (0.8)                                │    │
/// │  │ 2. "用户说他喜欢猫咪" (0.7)                          │    │
/// │  │ 3. "用户名字叫小明" (0.9)                            │    │
/// │  │ 4. "用户今天心情不好" (0.3)                          │    │
/// │  │ 5. "用户提到喜欢猫" (0.6)                            │    │
/// │  └─────────────────────────────────────────────────────┘    │
/// │                         │                                    │
/// │                         ▼                                    │
/// │  压缩后:                                                     │
/// │  ┌─────────────────────────────────────────────────────┐    │
/// │  │ 1. "用户喜欢猫" (0.8) ← 合并了 2, 5                  │    │
/// │  │ 2. "用户名字叫小明" (0.9)                            │    │
/// │  │ 3. "用户今天心情不好" (0.3) ← 可能被清理             │    │
/// │  └─────────────────────────────────────────────────────┘    │
/// │                                                              │
/// └─────────────────────────────────────────────────────────────┘
/// ```
class MemoryCompactor {
  /// 相似度阈值（0-1，越高要求越严格）
  final double similarityThreshold;
  
  /// 衰减系数（每天衰减多少）
  final double decayRate;
  
  /// 最低重要性阈值（低于此值可被清理）
  final double minImportance;

  MemoryCompactor({
    this.similarityThreshold = 0.6,
    this.decayRate = 0.02,
    this.minImportance = 0.2,
  });

  /// 检测两条记忆是否相似
  /// 
  /// 使用 Jaccard 相似度：交集大小 / 并集大小
  bool areSimilar(String memory1, String memory2) {
    final words1 = _tokenize(memory1);
    final words2 = _tokenize(memory2);
    
    if (words1.isEmpty || words2.isEmpty) return false;
    
    final intersection = words1.intersection(words2);
    final union = words1.union(words2);
    
    final similarity = intersection.length / union.length;
    return similarity >= similarityThreshold;
  }

  /// 计算两条记忆的相似度分数
  double calculateSimilarity(String memory1, String memory2) {
    final words1 = _tokenize(memory1);
    final words2 = _tokenize(memory2);
    
    if (words1.isEmpty || words2.isEmpty) return 0.0;
    
    final intersection = words1.intersection(words2);
    final union = words1.union(words2);
    
    return intersection.length / union.length;
  }

  /// 分词（简单实现）
  Set<String> _tokenize(String text) {
    // 移除标点和停用词
    const stopWords = {
      '用户', '说', '的', '了', '是', '在', '我', '你', '他', '她',
      '这', '那', '有', '和', '与', '或', '但', '提到', '表示',
    };
    
    return text
        .replaceAll(RegExp(r'[，。！？、；：""''（）\[\]【】:,.]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2 && !stopWords.contains(w))
        .toSet();
  }

  /// 合并相似记忆
  /// 
  /// 策略：保留重要性最高的那条，删除其他
  List<MemoryMergeResult> findMergeCandidates(List<MemoryItem> memories) {
    final results = <MemoryMergeResult>[];
    final processed = <int>{};
    
    for (var i = 0; i < memories.length; i++) {
      if (processed.contains(i)) continue;
      
      final similar = <int>[i];
      
      for (var j = i + 1; j < memories.length; j++) {
        if (processed.contains(j)) continue;
        
        if (areSimilar(memories[i].content, memories[j].content)) {
          similar.add(j);
          processed.add(j);
        }
      }
      
      if (similar.length > 1) {
        // 找出重要性最高的
        final items = similar.map((idx) => memories[idx]).toList();
        items.sort((a, b) => b.importance.compareTo(a.importance));
        
        results.add(MemoryMergeResult(
          keep: items.first,
          remove: items.skip(1).toList(),
        ));
      }
      
      processed.add(i);
    }
    
    return results;
  }

  /// 计算衰减后的重要性
  /// 
  /// 公式：importance * (1 - decayRate) ^ daysSinceAccess
  double calculateDecayedImportance(
    double originalImportance,
    DateTime lastAccessed,
  ) {
    final daysSinceAccess = DateTime.now().difference(lastAccessed).inDays;
    if (daysSinceAccess <= 0) return originalImportance;
    
    final decayFactor = (1 - decayRate);
    final decayedImportance = originalImportance * 
        _pow(decayFactor, daysSinceAccess);
    
    return decayedImportance.clamp(0.0, 1.0);
  }

  /// 简单的幂运算
  double _pow(double base, int exponent) {
    double result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  /// 找出可以清理的记忆
  List<MemoryItem> findCleanupCandidates(List<MemoryItem> memories) {
    return memories.where((m) {
      final decayedImportance = calculateDecayedImportance(
        m.importance,
        m.lastAccessedAt ?? m.createdAt,
      );
      return decayedImportance < minImportance;
    }).toList();
  }

  /// 执行完整的压缩流程
  CompactionResult compact(List<MemoryItem> memories) {
    // 1. 找出相似记忆
    final mergeResults = findMergeCandidates(memories);
    
    // 2. 找出可清理的记忆
    final cleanupCandidates = findCleanupCandidates(memories);
    
    // 3. 计算统计信息
    final toRemove = <int>{};
    for (final merge in mergeResults) {
      for (final item in merge.remove) {
        toRemove.add(item.id);
      }
    }
    for (final item in cleanupCandidates) {
      toRemove.add(item.id);
    }
    
    return CompactionResult(
      mergeResults: mergeResults,
      cleanupCandidates: cleanupCandidates,
      totalMemories: memories.length,
      toRemoveCount: toRemove.length,
      estimatedSavings: toRemove.length / memories.length,
    );
  }
}

/// 记忆项（用于压缩计算）
class MemoryItem {
  final int id;
  final String content;
  final double importance;
  final DateTime createdAt;
  final DateTime? lastAccessedAt;
  final int accessCount;

  const MemoryItem({
    required this.id,
    required this.content,
    required this.importance,
    required this.createdAt,
    this.lastAccessedAt,
    this.accessCount = 0,
  });
}

/// 合并结果
class MemoryMergeResult {
  /// 保留的记忆
  final MemoryItem keep;
  
  /// 要删除的记忆
  final List<MemoryItem> remove;

  const MemoryMergeResult({
    required this.keep,
    required this.remove,
  });
}

/// 压缩结果
class CompactionResult {
  final List<MemoryMergeResult> mergeResults;
  final List<MemoryItem> cleanupCandidates;
  final int totalMemories;
  final int toRemoveCount;
  final double estimatedSavings;

  const CompactionResult({
    required this.mergeResults,
    required this.cleanupCandidates,
    required this.totalMemories,
    required this.toRemoveCount,
    required this.estimatedSavings,
  });

  @override
  String toString() => 
      'CompactionResult(total: $totalMemories, toRemove: $toRemoveCount, '
      'savings: ${(estimatedSavings * 100).toStringAsFixed(1)}%)';
}
