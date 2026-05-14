import 'package:lumi/core/utils/logger.dart';
import 'package:lumi/features/soul/domain/entities/emotion.dart';

class ParsedResponse {
  final String text;
  final EmotionType emotion;
  const ParsedResponse({required this.text, required this.emotion});
}

class ResponseParser {
  // 匹配 [Emotion] 标签，可以在末尾或中间
  static final _emotionRegex = RegExp(r'\[(\w+)\]');

  // 有效的情绪标签
  static const _validTags = {
    'happy',
    'sad',
    'angry',
    'surprised',
    'shy',
    'curious',
    'neutral',
    'loving',
    'worried',
  };

  static ParsedResponse parse(String response) {
    EmotionType emotion = EmotionType.neutral;
    String text = response;
    EmotionType? matchedEmotion;

    // 查找所有 [Tag] 匹配
    final matches = _emotionRegex.allMatches(response).toList();

    for (final match in matches.reversed) {
      final tag = match.group(1)!.toLowerCase();
      if (_validTags.contains(tag)) {
        matchedEmotion = EmotionType.fromTag(tag);
        break;
      }
    }

    if (matchedEmotion != null) {
      emotion = matchedEmotion;
      // 清理所有有效情感标签
      text = response.replaceAllMapped(_emotionRegex, (match) {
        final tag = match.group(1)!.toLowerCase();
        return _validTags.contains(tag) ? '' : match.group(0)!;
      }).trim();
      AppLogger.i('Parsed emotion: ${emotion.name}');
    } else {
      // 如果没有找到标签，尝试从内容推断
      emotion = _inferFromContent(response);
      if (emotion != EmotionType.neutral) {
        AppLogger.i('Inferred emotion: ${emotion.name} from content');
      }
    }

    return ParsedResponse(text: text, emotion: emotion);
  }

  /// 从内容推断情绪
  static EmotionType _inferFromContent(String text) {
    final t = text;
    final tLower = text.toLowerCase();

    final scores = <EmotionType, int>{
      EmotionType.sad: 0,
      EmotionType.worried: 0,
      EmotionType.shy: 0,
      EmotionType.surprised: 0,
      EmotionType.angry: 0,
      EmotionType.curious: 0,
      EmotionType.happy: 0,
      EmotionType.loving: 0,
    };

    void addScore(EmotionType emotion, int score) {
      scores[emotion] = (scores[emotion] ?? 0) + score;
    }

    void scoreAny(
      EmotionType emotion,
      String source,
      List<String> patterns,
      int score,
    ) {
      for (final pattern in patterns) {
        if (source.contains(pattern)) {
          addScore(emotion, score);
        }
      }
    }

    // 强特征：颜文字和明确情绪词
    scoreAny(EmotionType.sad, t, ['T_T', 'QAQ', 'TAT', '呜呜'], 3);
    scoreAny(EmotionType.sad, tLower, ['哭了', '眼泪', '伤心', '难过', '失落', '委屈'], 3);

    scoreAny(EmotionType.worried, t, ['｡•́︿•̀｡', '(´;ω;`)'], 3);
    scoreAny(EmotionType.worried, tLower, [
      '担心',
      '没事吧',
      '还好吗',
      '不舒服',
      '烦恼',
      '陪着你',
    ], 3);

    scoreAny(EmotionType.shy, t, ['///', '>//<'], 3);
    scoreAny(EmotionType.shy, tLower, ['脸红', '不好意思', '害羞', '羞'], 3);

    scoreAny(EmotionType.surprised, t, ['!?', '？！', 'Σ'], 3);
    scoreAny(EmotionType.surprised, tLower, [
      '真的吗',
      '不会吧',
      '天哪',
      '居然',
      '没想到',
    ], 3);

    scoreAny(EmotionType.angry, tLower, ['生气', '讨厌', '可恶', '气死', '烦死'], 3);

    scoreAny(EmotionType.curious, t, ['´･ω･', '・ω・'], 3);
    scoreAny(EmotionType.curious, tLower, [
      '是什么',
      '为什么',
      '好奇',
      '想知道',
      '原来是这样',
    ], 3);

    scoreAny(EmotionType.happy, t, [
      '≧▽≦',
      '≧∇≦',
      '^_^',
      '◕ᴗ◕',
      '(*´▽`*)',
      '(≧◡≦)',
      '♪',
    ], 3);
    scoreAny(EmotionType.happy, tLower, [
      '开心',
      '太好了',
      '耶',
      '好棒',
      '厉害',
      '嘻嘻',
    ], 3);

    scoreAny(EmotionType.loving, t, ['♡', '❤'], 3);
    scoreAny(EmotionType.loving, tLower, ['喜欢你', '爱你', '想你', '抱抱', '亲亲'], 3);

    // 弱特征：只加少量分，避免一句普通话直接误判
    scoreAny(EmotionType.curious, tLower, ['怎么', '？', '?'], 1);
    scoreAny(EmotionType.happy, tLower, ['谢谢', '好呀', '喜欢'], 1);

    final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);

    // 分数太低就保持中性
    if (best.value < 2) {
      return EmotionType.neutral;
    }

    return best.key;
  }
}
