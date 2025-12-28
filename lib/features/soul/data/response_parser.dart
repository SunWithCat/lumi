import 'package:waifu/features/soul/domain/entities/emotion.dart';

class ParsedResponse {
  final String text;
  final EmotionType emotion;
  const ParsedResponse({required this.text, required this.emotion});
}

class ResponseParser {
  static ParsedResponse parse(String response) {
    final emotionRegex = RegExp(r'\[(\w+)\]\s*$');
    final match = emotionRegex.firstMatch(response);

    EmotionType emotion = EmotionType.neutral;
    String text = response;

    if (match != null) {
      final tag = match.group(1)!;
      emotion = EmotionType.fromTag(tag);
      text = response.substring(0, match.start).trim();
    } else {
      emotion = _inferFromEmoji(response);
    }
    return ParsedResponse(text: text, emotion: emotion);
  }

  static EmotionType _inferFromEmoji(String t) {
    if (t.contains('happy') || t.contains('')) return EmotionType.happy;
    if (t.contains('///') || t.contains('>_<')) return EmotionType.shy;
    if (t.contains('T_T')) return EmotionType.worried;
    if (t.contains('!?')) return EmotionType.surprised;
    if (t.contains('?')) return EmotionType.curious;
    return EmotionType.neutral;
  }
}
