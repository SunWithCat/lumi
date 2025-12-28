import 'package:waifu/features/soul/domain/entities/emotion.dart';

/// 情绪到 Live2D 动作的映射
class EmotionMotionMapper {
  /// 根据情绪获取对应的动作组和索引
  static MotionMapping getMotionForEmotion(EmotionType emotion) {
    return switch (emotion) {
      // 开心/喜爱 - Tap 动作（活泼）
      EmotionType.happy => const MotionMapping('Tap', 0, priority: 3),
      EmotionType.loving => const MotionMapping('Tap', 1, priority: 3),
      
      // 惊讶 - FlickUp 动作
      EmotionType.surprised => const MotionMapping('FlickUp', 0, priority: 3),
      
      // 好奇 - FlickDown 动作
      EmotionType.curious => const MotionMapping('FlickDown', 0, priority: 2),
      
      // 害羞 - Flick@Body 动作
      EmotionType.shy => const MotionMapping('Flick@Body', 0, priority: 3),
      
      // 担心 - Tap@Body 动作
      EmotionType.worried => const MotionMapping('Tap@Body', 0, priority: 2),
      
      // 悲伤/生气 - 使用不同的 Idle 动作
      EmotionType.sad => const MotionMapping('Idle', 1, priority: 2),
      EmotionType.angry => const MotionMapping('Flick', 0, priority: 3),
      
      // 中性 - 默认 Idle
      EmotionType.neutral => const MotionMapping('Idle', 0, priority: 1),
    };
  }
}

/// 动作映射数据
class MotionMapping {
  final String group;
  final int index;
  final int priority;

  const MotionMapping(this.group, this.index, {this.priority = 2});
}
