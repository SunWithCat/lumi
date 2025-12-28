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
    'happy', 'sad', 'angry', 'surprised', 'shy', 
    'curious', 'neutral', 'loving', 'worried'
  };

  static ParsedResponse parse(String response) {
    EmotionType emotion = EmotionType.neutral;
    String text = response;

    // 查找所有 [Tag] 匹配
    final matches = _emotionRegex.allMatches(response);
    
    for (final match in matches) {
      final tag = match.group(1)!.toLowerCase();
      if (_validTags.contains(tag)) {
        emotion = EmotionType.fromTag(tag);
        // 移除情绪标签
        text = response.replaceAll(match.group(0)!, '').trim();
        AppLogger.i('Parsed emotion: ${emotion.name} from tag [$tag]');
        break;
      }
    }

    // 如果没有找到标签，尝试从内容推断
    if (emotion == EmotionType.neutral) {
      emotion = _inferFromContent(response);
      if (emotion != EmotionType.neutral) {
        AppLogger.i('Inferred emotion: ${emotion.name} from content');
      }
    }

    return ParsedResponse(text: text, emotion: emotion);
  }

  /// 从内容推断情绪
  static EmotionType _inferFromContent(String text) {
    // 不转小写，因为颜文字区分大小写
    final t = text;
    final tLower = text.toLowerCase();
    
    // 悲伤/哭泣 - 优先检查
    if (_containsAny(t, ['T_T', 'QAQ', 'TAT', '呜呜', '哭', '泪', '伤心', '难过'])) {
      return EmotionType.sad;
    }
    
    // 担心/关心
    if (_containsAny(t, ['｡•́︿•̀｡', '(´;ω;`)']) ||
        _containsAny(tLower, ['担心', '怎么了', '不开心', '没事吧', '还好吗', '烦恼', '陪着', '分享'])) {
      return EmotionType.worried;
    }
    
    // 害羞
    if (_containsAny(t, ['///', '>//<', '>_<', '>.<']) || 
        _containsAny(tLower, ['羞', '脸红', '不好意思', '害羞'])) {
      return EmotionType.shy;
    }
    
    // 惊讶
    if (_containsAny(t, ['!?', '？！', 'Σ', '!!']) ||
        _containsAny(tLower, ['诶', '哇', '真的吗', '不会吧', '天哪'])) {
      return EmotionType.surprised;
    }
    
    // 生气
    if (_containsAny(tLower, ['哼', '生气', '讨厌', '可恶', '气死'])) {
      return EmotionType.angry;
    }
    
    // 好奇 - 问号相关放后面，避免误匹配
    if (_containsAny(t, ['´･ω･', '・ω・']) ||
        _containsAny(tLower, ['是什么', '为什么', '怎么', '好奇', '想知道'])) {
      return EmotionType.curious;
    }
    
    // 开心/喜爱 - 放最后
    if (_containsAny(t, ['≧▽≦', '≧∇≦', '♡', '❤', '^_^', '(๑', '◕ᴗ◕', '✿', '♪', '~', '(*´▽`*)', '(≧◡≦)']) ||
        _containsAny(tLower, ['喜欢', '开心', '太好了', '耶', '棒', '爱', '谢谢', '厉害', '好呀', '嘻嘻'])) {
      return EmotionType.happy;
    }

    return EmotionType.neutral;
  }

  static bool _containsAny(String text, List<String> patterns) {
    return patterns.any((p) => text.contains(p));
  }
}
