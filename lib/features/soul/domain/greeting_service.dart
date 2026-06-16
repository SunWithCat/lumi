import 'dart:math';

import 'package:lumi/features/soul/domain/entities/emotion.dart';
import 'package:lumi/features/soul/domain/entities/greeting_templates.dart';
import 'package:lumi/features/soul/domain/entities/persona_config.dart';

/// 问候判定结果
class GreetingResult {
  final GreetingTemplate template;
  final ReunionType reunionType;

  const GreetingResult({required this.template, required this.reunionType});
}

class GreetingService {
  static const _cooldownHours = 2;
  static final _random = Random();

  /// 判定是否应该发送问候
  GreetingResult? evaluate({
    required DateTime now,
    required DateTime? lastGreetingTime,
    required bool hasHistory,
    required PersonaConfig persona,
  }) {
    if (!hasHistory) {
      final template = _pickTemplate(
        ReunionType.firstMeet,
        now: now,
        persona: persona,
      );
      return GreetingResult(
        template: template,
        reunionType: ReunionType.firstMeet,
      );
    }

    if (lastGreetingTime != null) {
      final gap = now.difference(lastGreetingTime);

      if (gap.inHours < _cooldownHours) {
        return null;
      }

      final reunionType = _getReunionType(gap);
      final template = _pickTemplate(reunionType, now: now, persona: persona);

      return GreetingResult(template: template, reunionType: reunionType);
    }

    final timePeriod = getTimePeriod(now);
    final template = _pickTimePeriodTemplate(timePeriod, persona: persona);
    return GreetingResult(template: template, reunionType: ReunionType.normal);
  }

  /// 获取当前时间段
  TimePeriod getTimePeriod(DateTime time) {
    final hour = time.hour;
    return switch (hour) {
      >= 5 && < 8 => TimePeriod.earlyMorning,
      >= 8 && < 11 => TimePeriod.morning,
      >= 11 && < 13 => TimePeriod.noon,
      >= 13 && < 17 => TimePeriod.afternoon,
      >= 17 && < 19 => TimePeriod.evening,
      >= 19 && < 22 => TimePeriod.night,
      _ => TimePeriod.lateNight, // 22:00-04:59
    };
  }

  /// 获取重逢类型
  ReunionType _getReunionType(Duration gap) {
    if (gap.inDays >= 3) {
      return ReunionType.longAbsence;
    } else if (gap.inDays >= 1) {
      return ReunionType.nextDay;
    } else {
      return ReunionType.normal;
    }
  }

  /// 选取模板（重逢类型优先，否则使用时间段）
  GreetingTemplate _pickTemplate(
    ReunionType reunionType, {
    required DateTime now,
    required PersonaConfig persona,
  }) {
    // 首次相遇、隔日、久别使用重逢模板
    if (reunionType != ReunionType.normal) {
      final pool = GreetingTemplates.getTemplatesByReunion(
        reunionType,
        persona.id,
      );
      if (pool.isNotEmpty) {
        final template = _pickRandom(pool);
        return GreetingTemplates.applyUserTitle(template, persona.userTitle);
      }
    }

    // 常规使用时间段模板
    final timePeriod = getTimePeriod(now);
    return _pickTimePeriodTemplate(timePeriod, persona: persona);
  }

  /// 从时间段模板池中随机选取
  GreetingTemplate _pickTimePeriodTemplate(
    TimePeriod period, {
    required PersonaConfig persona,
  }) {
    final pool = GreetingTemplates.getTemplatesByTimePeriod(period, persona.id);
    final template = _pickRandom(pool);
    return GreetingTemplates.applyUserTitle(template, persona.userTitle);
  }

  /// 从模板池中随机选取一条
  GreetingTemplate _pickRandom(List<GreetingTemplate> pool) {
    if (pool.isEmpty) {
      return const GreetingTemplate(text: '你好呀～', emotion: EmotionType.neutral);
    }
    return pool[_random.nextInt(pool.length)];
  }
}
