import 'package:waifu/features/soul/domain/entities/emotion.dart';

/// LLM 响应解析结果
class ParsedResponse {
  final String text;
  final EmotionType emotion;

  const ParsedResponse({
    required this.text,
    required this.emotion,
  });
}

/// 响应解析器
class ResponseParser {
  /// 从 LLM 响应中解析文本和情感
  /// 
  /// 输入示例: "今天天气真好呢！(≧▽≦) [Happy]"
  /// 输出: ParsedResponse(text: "今天天气真好呢！(≧▽≦)", emotion: EmotionType.happy)
  static ParsedResponse parse(String response) {
    // 匹配情感标签 [Happy], [Sad] 等
    final emotionRegex = RegExp(r'\[(\w+)\]\s*$');
    final match = emotionRegex.firstMatch(response);

    EmotionType emotion = EmotionType.neutral;
    String text = response;

    if (match != null) {
      final tag = match.group(1)!;
      emotion = EmotionType.fromTag(tag);
      // 移除情感标签
      text = response.substring(0, match.start).trim();
    }

    return ParsedResponse(text: text, emotion: emotion);
  }
}
