/// 记忆重要性评估器
///
/// 负责判断一段对话是否值得被记住，以及记忆的重要程度。
///
/// ## 为什么需要记忆评估？
///
/// 不是所有对话都值得记住：
/// - "你好" → 不重要，不需要记
/// - "我叫小明" → 重要！用户身份信息
/// - "我喜欢猫" → 重要！用户偏好
/// - "今天天气真好" → 不太重要，闲聊
///
/// ## 评估策略
///
/// 1. 关键词匹配 - 检测特定词汇（名字、喜欢、生日等）
/// 2. 句式识别 - 检测自我介绍、偏好表达等句式
/// 3. 情感强度 - 强烈情感的对话更值得记住
/// 4. 信息密度 - 包含具体信息的对话更重要
class MemoryEvaluator {
  /// 高重要性关键词（用户身份、偏好）
  static const _highImportanceKeywords = [
    // 身份信息
    '我叫', '我的名字', '名字是', '我是',
    '我今年', '岁了', '生日',
    '我住在', '我在', '工作',

    // 偏好信息
    '我喜欢', '我爱', '我最喜欢', '我超喜欢',
    '我讨厌', '我不喜欢', '我害怕',
    '我想要', '我希望', '我的梦想',

    // 关系信息
    '我的朋友', '我的家人', '我的父母', '我的男朋友', '我的女朋友',
    '我养了', '我有一只', '我有一个',
  ];

  /// 中等重要性关键词（情感、经历）
  static const _mediumImportanceKeywords = [
    // 情感表达
    '好开心', '好难过', '好生气', '好累', '好烦',
    '太棒了', '太糟糕', '受不了',

    // 经历分享
    '今天发生', '昨天', '上周', '最近',
    '我去了', '我看了', '我吃了', '我买了',

    // 计划意图
    '我打算', '我准备', '我要去', '明天',
  ];

  /// 低重要性模式（闲聊、问候）
  static const _lowImportancePatterns = [
    '你好',
    '早上好',
    '晚上好',
    '晚安',
    '在吗',
    '在干嘛',
    '干嘛呢',
    '哈哈',
    '嗯嗯',
    '好的',
    '知道了',
    '谢谢',
    '不客气',
    '没关系',
  ];

  /// 评估一条消息的记忆重要性
  ///
  /// 返回 0.0-1.0 的重要性分数：
  /// - 0.0-0.3: 不值得记忆
  /// - 0.3-0.6: 可选记忆
  /// - 0.6-1.0: 重要记忆
  MemoryEvaluation evaluate(String userMessage, {String? aiResponse}) {
    double score = 0.0;
    final reasons = <String>[];

    // 1. 检查高重要性关键词
    for (final keyword in _highImportanceKeywords) {
      if (userMessage.contains(keyword)) {
        score += 0.4;
        reasons.add('包含关键信息: "$keyword"');
        break; // 只计一次
      }
    }

    // 2. 检查中等重要性关键词
    for (final keyword in _mediumImportanceKeywords) {
      if (userMessage.contains(keyword)) {
        score += 0.2;
        reasons.add('包含经历/情感: "$keyword"');
        break;
      }
    }

    // 3. 检查低重要性模式（降分）
    for (final pattern in _lowImportancePatterns) {
      if (userMessage.trim() == pattern ||
          userMessage.length < 5 && userMessage.contains(pattern)) {
        score -= 0.3;
        reasons.add('简单问候/闲聊');
        break;
      }
    }

    // 4. 消息长度加分（长消息通常包含更多信息）
    if (userMessage.length > 50) {
      score += 0.1;
      reasons.add('详细描述');
    }
    if (userMessage.length > 100) {
      score += 0.1;
      reasons.add('非常详细');
    }

    // 5. 包含数字（可能是具体信息）
    if (RegExp(r'\d+').hasMatch(userMessage)) {
      score += 0.1;
      reasons.add('包含具体数字');
    }

    // 6. 包含专有名词（大写字母开头或引号内容）
    if (RegExp(r'「.+」|".+"').hasMatch(userMessage)) {
      score += 0.1;
      reasons.add('包含专有名词');
    }

    // 确保分数在 0-1 范围内
    score = score.clamp(0.0, 1.0);

    return MemoryEvaluation(
      score: score,
      shouldRemember: score >= 0.3,
      reasons: reasons,
      suggestedContent: _extractMemoryContent(userMessage),
    );
  }

  /// 提取值得记忆的内容
  ///
  /// 将用户消息转换为简洁的记忆格式
  String _extractMemoryContent(String userMessage) {
    // 简单处理：直接使用原文，后续可以用 LLM 提取
    if (userMessage.length > 100) {
      return '${userMessage.substring(0, 100)}...';
    }
    return userMessage;
  }

  /// 批量评估对话，提取值得记忆的内容
  List<MemoryCandidate> evaluateConversation(
    List<(String user, String ai)> exchanges,
  ) {
    final candidates = <MemoryCandidate>[];

    for (final (userMsg, aiMsg) in exchanges) {
      final eval = evaluate(userMsg, aiResponse: aiMsg);
      if (eval.shouldRemember) {
        candidates.add(
          MemoryCandidate(
            content: eval.suggestedContent,
            importance: eval.score,
            source: userMsg,
          ),
        );
      }
    }

    // 按重要性排序
    candidates.sort((a, b) => b.importance.compareTo(a.importance));
    return candidates;
  }
}

/// 记忆评估结果
class MemoryEvaluation {
  /// 重要性分数 (0.0-1.0)
  final double score;

  /// 是否应该记住
  final bool shouldRemember;

  /// 评估理由
  final List<String> reasons;

  /// 建议的记忆内容
  final String suggestedContent;

  const MemoryEvaluation({
    required this.score,
    required this.shouldRemember,
    required this.reasons,
    required this.suggestedContent,
  });

  @override
  String toString() =>
      'MemoryEvaluation(score: $score, remember: $shouldRemember, reasons: $reasons)';
}

/// 记忆候选
class MemoryCandidate {
  final String content;
  final double importance;
  final String source;

  const MemoryCandidate({
    required this.content,
    required this.importance,
    required this.source,
  });
}
