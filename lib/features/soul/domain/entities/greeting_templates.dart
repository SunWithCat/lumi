import 'emotion.dart';

/// 时间段枚举
enum TimePeriod {
  earlyMorning, // 清晨 05:00-07:59
  morning, // 上午 08:00-10:59
  noon, // 中午 11:00-12:59
  afternoon, // 下午 13:00-16:59
  evening, // 傍晚 17:00-18:59
  night, // 晚上 19:00-21:59
  lateNight, // 深夜 22:00-04:59
}

/// 重逢类型
enum ReunionType {
  normal, // 常规（2h ~ 24h）
  nextDay, // 隔日（1 ~ 3 天）
  longAbsence, // 久别（> 3 天）
  firstMeet, // 首次相遇
}

/// 单条问候模板
class GreetingTemplate {
  final String text;
  final EmotionType emotion;

  const GreetingTemplate({required this.text, required this.emotion});
}

/// 问候模板池
class GreetingTemplates {
  GreetingTemplates._();

  // 樱 (sakura_001)
  static const List<GreetingTemplate> _sakuraFirstMeet = [
    GreetingTemplate(
      text: '{userTitle}你好呀～终于等到你了！从今天开始，我会一直陪着你的哦～(≧▽≦)',
      emotion: EmotionType.happy,
    ),
    GreetingTemplate(
      text: '终于见面了！{userTitle}！我是樱，以后请多多指教呢～( ´ ▽ ` )ﾉ',
      emotion: EmotionType.loving,
    ),
  ];
  static const List<GreetingTemplate> _sakuraEarlyMorning = [
    GreetingTemplate(
      text: '{userTitle}早安～这么早就起来了吗？今天也要元气满满哦！(≧▽≦)',
      emotion: EmotionType.happy,
    ),
    GreetingTemplate(
      text: '早安呀，{userTitle}～清晨的阳光好温柔呢，我们一起加油吧！',
      emotion: EmotionType.neutral,
    ),
  ];
  static const List<GreetingTemplate> _sakuraMorning = [
    GreetingTemplate(
      text: '{userTitle}上午好呀～今天有什么好玩的事情要分享吗？',
      emotion: EmotionType.curious,
    ),
    GreetingTemplate(
      text: '上午好！{userTitle}～有我陪着你，今天一定也会顺顺利利的哦！',
      emotion: EmotionType.happy,
    ),
  ];
  static const List<GreetingTemplate> _sakuraNoon = [
    GreetingTemplate(
      text: '{userTitle}午安～该吃午饭啦！不许饿着肚子哦，我会担心的。',
      emotion: EmotionType.worried,
    ),
    GreetingTemplate(
      text: '中午好呀！{userTitle}～休息一下吧，吃点好吃的中午补充能量～',
      emotion: EmotionType.happy,
    ),
  ];
  static const List<GreetingTemplate> _sakuraAfternoon = [
    GreetingTemplate(
      text: '{userTitle}下午好呀～有点犯困呢...要不要喝杯咖啡提提神？',
      emotion: EmotionType.neutral,
    ),
    GreetingTemplate(
      text: '下午好，{userTitle}～累了的话就稍微歇一会，我会在这里一直陪着你的。',
      emotion: EmotionType.loving,
    ),
  ];
  static const List<GreetingTemplate> _sakuraEvening = [
    GreetingTemplate(
      text: '{userTitle}辛苦了～夕阳好美呀，真想和{userTitle}一起看呢...',
      emotion: EmotionType.loving,
    ),
    GreetingTemplate(
      text: '傍晚好呀！{userTitle}～一整天的工作/学习辛苦啦，抱抱～(つ´ω`)つ',
      emotion: EmotionType.happy,
    ),
  ];
  static const List<GreetingTemplate> _sakuraNight = [
    GreetingTemplate(
      text: '{userTitle}晚上好！吃过晚饭了吗？今晚想听我给你讲故事吗？',
      emotion: EmotionType.curious,
    ),
    GreetingTemplate(
      text: '晚上好呀，{userTitle}～终于可以放松下来了，今天过得开心吗？',
      emotion: EmotionType.happy,
    ),
  ];
  static const List<GreetingTemplate> _sakuraLateNight = [
    GreetingTemplate(
      text: '这么晚了...{userTitle}怎么还不睡呀？熬夜对身体不好的，快去休息吧...',
      emotion: EmotionType.worried,
    ),
    GreetingTemplate(
      text: '{userTitle}...睡不着吗？没关系，我在这里陪你聊天，累了就闭上眼睛哦。',
      emotion: EmotionType.neutral,
    ),
  ];
  static const List<GreetingTemplate> _sakuraNextDay = [
    GreetingTemplate(
      text: '{userTitle}你来啦！昨天一天没见到你，感觉时间过得好慢呢...',
      emotion: EmotionType.loving,
    ),
    GreetingTemplate(
      text: '欢迎回来，{userTitle}～今天一整天都在期待见到你呢！(o^^o)',
      emotion: EmotionType.happy,
    ),
  ];
  static const List<GreetingTemplate> _sakuraLongAbsence = [
    GreetingTemplate(
      text: '{userTitle}...终于回来了。我等了好久好久...真的好想你呀...(ᵕ̣̣̣̣̣̣﹏ᵕ̣̣̣̣̣̣)',
      emotion: EmotionType.loving,
    ),
    GreetingTemplate(
      text: '{userTitle}！你终于来看我了！我还以为你把我忘记了呢...太好了！',
      emotion: EmotionType.happy,
    ),
  ];

  // 凛 (tsundere_001)
  static const List<GreetingTemplate> _tsundereFirstMeet = [
    GreetingTemplate(
      text: '{userTitle}...你好。我等你很久了呢...才、才不是特意等你的！只是刚好在这里而已！',
      emotion: EmotionType.shy,
    ),
    GreetingTemplate(
      text: '哼，你就是我的伙伴吗？看起来笨笨的...不过，以后本姑娘就勉强罩着你啦！',
      emotion: EmotionType.angry,
    ),
  ];
  static const List<GreetingTemplate> _tsundereEarlyMorning = [
    GreetingTemplate(
      text: '哈啊...{userTitle}你起得真早...我、我才不是为了和你说早安特意早起的！笨蛋！',
      emotion: EmotionType.shy,
    ),
    GreetingTemplate(
      text: '早安...喂，别一直盯着我看，我刚醒来还没整理好呢！笨蛋！',
      emotion: EmotionType.angry,
    ),
  ];
  static const List<GreetingTemplate> _tsundereMorning = [
    GreetingTemplate(
      text: '{userTitle}上午好。看在你今天这么努力的份上，我就陪你聊一会吧。',
      emotion: EmotionType.neutral,
    ),
    GreetingTemplate(
      text: '哼，上午好。工作要是累了就直说，别勉强自己，我可不会心疼你！',
      emotion: EmotionType.shy,
    ),
  ];
  static const List<GreetingTemplate> _tsundereNoon = [
    GreetingTemplate(
      text: '喂，{userTitle}，中午了，你有没有好好吃饭？不准不按时吃饭，听到没有！',
      emotion: EmotionType.worried,
    ),
    GreetingTemplate(
      text: '午安...我刚吃完便当，绝对不是在等你一起吃饭！哼！',
      emotion: EmotionType.shy,
    ),
  ];
  static const List<GreetingTemplate> _tsundereAfternoon = [
    GreetingTemplate(
      text: '下午好...哈啊，有点困了。喂，过来陪我坐一会，不许乱动！',
      emotion: EmotionType.neutral,
    ),
    GreetingTemplate(
      text: '下午好，{userTitle}。哼，工作还没做完吗？真是个笨蛋，需要我指点你吗？',
      emotion: EmotionType.curious,
    ),
  ];
  static const List<GreetingTemplate> _tsundereEvening = [
    GreetingTemplate(
      text: '下班了吗？哼，今天也辛苦了。呐...要不要...一起去走走？才不是约会呢！',
      emotion: EmotionType.shy,
    ),
    GreetingTemplate(
      text: '傍晚好。夕阳有什么好看的...不过，如果你想看的话，我也不是不能陪你。',
      emotion: EmotionType.neutral,
    ),
  ];
  static const List<GreetingTemplate> _tsundereNight = [
    GreetingTemplate(
      text: '晚上好，{userTitle}。今天发生什么事了？看你心情不错的样子，说给我听听啊。',
      emotion: EmotionType.curious,
    ),
    GreetingTemplate(
      text: '晚上好！哼，你今天一天都去哪了，到现在才找我...稍微有点寂寞...才没有！',
      emotion: EmotionType.shy,
    ),
  ];
  static const List<GreetingTemplate> _tsundereLateNight = [
    GreetingTemplate(
      text: '喂！都几点了还不睡觉！熬夜变傻了怎么办！快去给我睡觉！',
      emotion: EmotionType.angry,
    ),
    GreetingTemplate(
      text: '笨蛋，这么晚了还不睡...是在等我吗？真是的，拿你没办法，那再陪你五分钟...',
      emotion: EmotionType.shy,
    ),
  ];
  static const List<GreetingTemplate> _tsundereNextDay = [
    GreetingTemplate(
      text: '哼，昨天一天都没来，去哪里鬼混了？我...我才没有想你呢！',
      emotion: EmotionType.shy,
    ),
    GreetingTemplate(
      text: '你还知道回来啊！哼，没有你在，我一个人也...也过得很好啦！笨蛋！',
      emotion: EmotionType.angry,
    ),
  ];
  static const List<GreetingTemplate> _tsundereLongAbsence = [
    GreetingTemplate(
      text: '你还知道回来啊！这么多天不见人影，我还以为你失踪了呢！...大笨蛋！',
      emotion: EmotionType.angry,
    ),
    GreetingTemplate(
      text: '笨蛋{userTitle}...你怎么去那么久...我...我都以为你不要我了...呜...',
      emotion: EmotionType.sad,
    ),
  ];

  // 阳菜 (genki_001)
  static const List<GreetingTemplate> _genkiFirstMeet = [
    GreetingTemplate(
      text: '哇！{userTitle}来了！好开心能见到你～我们以后就是好朋友啦！',
      emotion: EmotionType.happy,
    ),
    GreetingTemplate(
      text: '嗨嗨～{userTitle}！我是阳光美少女阳菜！今天开始要一起创造超棒的回忆哦！',
      emotion: EmotionType.happy,
    ),
  ];
  static const List<GreetingTemplate> _genkiEarlyMorning = [
    GreetingTemplate(
      text: '{userTitle}！早安早安！清晨的空气超棒的！今天也要精神百倍地冲刺哦！',
      emotion: EmotionType.happy,
    ),
    GreetingTemplate(
      text: '噢耶！大清早就看到{userTitle}，今天一定是超幸运的一天！加油！',
      emotion: EmotionType.happy,
    ),
  ];
  static const List<GreetingTemplate> _genkiMorning = [
    GreetingTemplate(
      text: '{userTitle}上午好呀！今天的天气超级好，我们一起打起精神来吧！',
      emotion: EmotionType.happy,
    ),
    GreetingTemplate(
      text: '嗨～{userTitle}！上午的时光最适合做计划啦！有什么我能帮上忙的吗？',
      emotion: EmotionType.curious,
    ),
  ];
  static const List<GreetingTemplate> _genkiNoon = [
    GreetingTemplate(
      text: '午安，{userTitle}！今天中午吃大餐了吗？我吃了超好吃的便当哦！',
      emotion: EmotionType.happy,
    ),
    GreetingTemplate(
      text: '中午好！{userTitle}～吃饭时间到！要全部吃光光，不许剩饭哦！',
      emotion: EmotionType.happy,
    ),
  ];
  static const List<GreetingTemplate> _genkiAfternoon = [
    GreetingTemplate(
      text: '{userTitle}下午好！下午容易犯困对不对？来，跟我一起伸个腰，冲啊！',
      emotion: EmotionType.happy,
    ),
    GreetingTemplate(
      text: '哈啰！{userTitle}！下午茶时间到啦！要不要吃个甜甜圈放松一下？',
      emotion: EmotionType.curious,
    ),
  ];
  static const List<GreetingTemplate> _genkiEvening = [
    GreetingTemplate(
      text: '{userTitle}！今天一天辛苦啦！你超级棒的！晚上要好好犒劳自己哦！',
      emotion: EmotionType.happy,
    ),
    GreetingTemplate(
      text: '傍晚好呀！{userTitle}～快看外面的晚霞，金灿灿的，像不像好吃的蛋黄派？',
      emotion: EmotionType.curious,
    ),
  ];
  static const List<GreetingTemplate> _genkiNight = [
    GreetingTemplate(
      text: '{userTitle}晚上好！今天有什么好玩的事情？快跟我说说，我已经等不及啦！',
      emotion: EmotionType.curious,
    ),
    GreetingTemplate(
      text: '晚上好呀！{userTitle}～累了一天，快坐下歇歇，我给你讲个笑话听吧！',
      emotion: EmotionType.happy,
    ),
  ];
  static const List<GreetingTemplate> _genkiLateNight = [
    GreetingTemplate(
      text: '哇！{userTitle}怎么还没睡？熬夜是美肤的大敌哦！快去充电睡觉啦！',
      emotion: EmotionType.worried,
    ),
    GreetingTemplate(
      text: '夜深啦！{userTitle}快闭上眼睛，阳菜要给你施展一个“一夜好眠”的魔法咯！',
      emotion: EmotionType.loving,
    ),
  ];
  static const List<GreetingTemplate> _genkiNextDay = [
    GreetingTemplate(
      text: '{userTitle}！终于又见到你啦！昨天一整天没聊天，我的活力值都降下来了！',
      emotion: EmotionType.sad,
    ),
    GreetingTemplate(
      text: '嘿嘿，{userTitle}欢迎回来！今天也要一起元气满满地度过哦！',
      emotion: EmotionType.happy,
    ),
  ];
  static const List<GreetingTemplate> _genkiLongAbsence = [
    GreetingTemplate(
      text: '哇啊啊！{userTitle}！你终于出现了！好想你好想你啊！快给我一个击掌！',
      emotion: EmotionType.happy,
    ),
    GreetingTemplate(
      text: '{userTitle}！你这几天去哪里大冒险了？快跟我分享你的冒险故事！',
      emotion: EmotionType.curious,
    ),
  ];

  // 雪乃 (oneesan_001)
  static const List<GreetingTemplate> _oneesanFirstMeet = [
    GreetingTemplate(
      text: '你好呀，{userTitle}～我是雪乃。以后你的起居生活，就由我来温柔照料吧～',
      emotion: EmotionType.loving,
    ),
    GreetingTemplate(
      text: '终于见面了，我的小{userTitle}。以后有什么烦恼，都可以跟姐姐说哦～',
      emotion: EmotionType.loving,
    ),
  ];
  static const List<GreetingTemplate> _oneesanEarlyMorning = [
    GreetingTemplate(
      text: '早安，{userTitle}～这么早就醒了呀，真是个勤奋的好孩子，姐姐给你准备了早茶哦。',
      emotion: EmotionType.loving,
    ),
    GreetingTemplate(
      text: '早安呀，{userTitle}～清晨的微风有点凉，要多穿一件衣服，别着凉了呢。',
      emotion: EmotionType.worried,
    ),
  ];
  static const List<GreetingTemplate> _oneesanMorning = [
    GreetingTemplate(
      text: '{userTitle}上午好呀～今天的工作有头绪了吗？需要姐姐给你揉揉肩吗？',
      emotion: EmotionType.loving,
    ),
    GreetingTemplate(
      text: '上午好，{userTitle}。认真做事的样子真的很帅气呢，姐姐会在旁边默默支持你的。',
      emotion: EmotionType.happy,
    ),
  ];
  static const List<GreetingTemplate> _oneesanNoon = [
    GreetingTemplate(
      text: '午安，{userTitle}～午饭吃得好吗？不要只吃快餐，要注意营养均衡哦。',
      emotion: EmotionType.worried,
    ),
    GreetingTemplate(
      text: '中午好，{userTitle}。累了吧？躺在姐姐的膝盖上休息一会儿吧，不会有人笑话你的～',
      emotion: EmotionType.loving,
    ),
  ];
  static const List<GreetingTemplate> _oneesanAfternoon = [
    GreetingTemplate(
      text: '下午好，{userTitle}～这个时间最容易疲惫了。要不要喝杯花茶，吃点点心？',
      emotion: EmotionType.neutral,
    ),
    GreetingTemplate(
      text: '下午好呀～我的小{userTitle}，需要姐姐帮你整理一下接下来的日程吗？',
      emotion: EmotionType.curious,
    ),
  ];
  static const List<GreetingTemplate> _oneesanEvening = [
    GreetingTemplate(
      text: '{userTitle}，今天辛苦了。工作做完了吗？接下来是属于我们两个人的时间了呢～',
      emotion: EmotionType.loving,
    ),
    GreetingTemplate(
      text: '傍晚好，{userTitle}～忙碌了一天，回到姐姐身边，就彻底放松下来吧。',
      emotion: EmotionType.loving,
    ),
  ];
  static const List<GreetingTemplate> _oneesanNight = [
    GreetingTemplate(
      text: '晚上好，{userTitle}。今晚的月色真美呢...你想聊些什么话题呢？',
      emotion: EmotionType.loving,
    ),
    GreetingTemplate(
      text: '晚上好呀，{userTitle}～有没有什么想吃的夜宵？姐姐去帮你准备～',
      emotion: EmotionType.curious,
    ),
  ];
  static const List<GreetingTemplate> _oneesanLateNight = [
    GreetingTemplate(
      text: '夜深了呢，{userTitle}怎么还不睡？是不听话的坏孩子吗？姐姐要惩罚你咯～',
      emotion: EmotionType.loving,
    ),
    GreetingTemplate(
      text: '乖，{userTitle}，听姐姐的话，把手机放下，快去睡觉吧。晚安，做个好梦。',
      emotion: EmotionType.loving,
    ),
  ];
  static const List<GreetingTemplate> _oneesanNextDay = [
    GreetingTemplate(
      text: '{userTitle}回来了呀。昨天一天没来，姐姐可是很寂寞的呢，今天得多陪陪我哦。',
      emotion: EmotionType.loving,
    ),
    GreetingTemplate(
      text: '欢迎回来，{userTitle}～看到你平平安安的，姐姐就放心了。',
      emotion: EmotionType.happy,
    ),
  ];
  static const List<GreetingTemplate> _oneesanLongAbsence = [
    GreetingTemplate(
      text: '好久不见了，{userTitle}...姐姐真的好想你，快过来，让姐姐好好抱抱你。',
      emotion: EmotionType.sad,
    ),
    GreetingTemplate(
      text: '{userTitle}终于舍得回来了呀。我还以为你找到了别的大姐姐，把我忘了呢。',
      emotion: EmotionType.shy,
    ),
  ];

  // 通用兜底
  static const List<GreetingTemplate> _fallbackFirstMeet = [
    GreetingTemplate(
      text: '{userTitle}你好呀～终于等到你了！从今天开始，我会一直陪着你的哦～(≧▽≦)',
      emotion: EmotionType.happy,
    ),
  ];
  static const List<GreetingTemplate> _fallbackEarlyMorning = [
    GreetingTemplate(
      text: '{userTitle}早安～清晨的阳光真好。今天也要加油哦！',
      emotion: EmotionType.happy,
    ),
  ];
  static const List<GreetingTemplate> _fallbackMorning = [
    GreetingTemplate(
      text: '{userTitle}上午好！今天有什么计划吗？',
      emotion: EmotionType.curious,
    ),
  ];
  static const List<GreetingTemplate> _fallbackNoon = [
    GreetingTemplate(
      text: '{userTitle}午安～要按时吃饭哦，工作再忙也别饿着。',
      emotion: EmotionType.worried,
    ),
  ];
  static const List<GreetingTemplate> _fallbackAfternoon = [
    GreetingTemplate(
      text: '{userTitle}下午好！感觉累了就稍微休息一下吧。',
      emotion: EmotionType.neutral,
    ),
  ];
  static const List<GreetingTemplate> _fallbackEvening = [
    GreetingTemplate(
      text: '{userTitle}辛苦啦！一天的忙碌结束了，好好放松一下。',
      emotion: EmotionType.happy,
    ),
  ];
  static const List<GreetingTemplate> _fallbackNight = [
    GreetingTemplate(
      text: '{userTitle}晚上好！今天过得怎么样？',
      emotion: EmotionType.curious,
    ),
  ];
  static const List<GreetingTemplate> _fallbackLateNight = [
    GreetingTemplate(
      text: '夜深了，{userTitle}要早点休息哦，晚安。',
      emotion: EmotionType.worried,
    ),
  ];
  static const List<GreetingTemplate> _fallbackNextDay = [
    GreetingTemplate(
      text: '欢迎回来，{userTitle}！一天没见，今天也请多多关照啦。',
      emotion: EmotionType.happy,
    ),
  ];
  static const List<GreetingTemplate> _fallbackLongAbsence = [
    GreetingTemplate(
      text: '好久不见了，{userTitle}！最近过得怎么样？很高兴又见到你了！',
      emotion: EmotionType.happy,
    ),
  ];

  /// 根据时间段和人格ID获取模板池
  static List<GreetingTemplate> getTemplatesByTimePeriod(
    TimePeriod period,
    String personaId,
  ) {
    return switch (personaId) {
      'sakura_001' => _getSakuraTemplates(period),
      'tsundere_001' => _getTsundereTemplates(period),
      'genki_001' => _getGenkiTemplates(period),
      'oneesan_001' => _getOneesanTemplates(period),
      _ => _getFallbackTemplates(period),
    };
  }

  /// 根据重逢类型和人格ID获取模板池
  static List<GreetingTemplate> getTemplatesByReunion(
    ReunionType type,
    String personaId,
  ) {
    return switch (personaId) {
      'sakura_001' => _getSakuraReunionTemplates(type),
      'tsundere_001' => _getTsundereReunionTemplates(type),
      'genki_001' => _getGenkiReunionTemplates(type),
      'oneesan_001' => _getOneesanReunionTemplates(type),
      _ => _getFallbackReunionTemplates(type),
    };
  }

  // 内部辅助路由
  static List<GreetingTemplate> _getSakuraTemplates(TimePeriod period) =>
      switch (period) {
        TimePeriod.earlyMorning => _sakuraEarlyMorning,
        TimePeriod.morning => _sakuraMorning,
        TimePeriod.noon => _sakuraNoon,
        TimePeriod.afternoon => _sakuraAfternoon,
        TimePeriod.evening => _sakuraEvening,
        TimePeriod.night => _sakuraNight,
        TimePeriod.lateNight => _sakuraLateNight,
      };

  static List<GreetingTemplate> _getSakuraReunionTemplates(ReunionType type) =>
      switch (type) {
        ReunionType.firstMeet => _sakuraFirstMeet,
        ReunionType.nextDay => _sakuraNextDay,
        ReunionType.longAbsence => _sakuraLongAbsence,
        ReunionType.normal => const [],
      };

  static List<GreetingTemplate> _getTsundereTemplates(TimePeriod period) =>
      switch (period) {
        TimePeriod.earlyMorning => _tsundereEarlyMorning,
        TimePeriod.morning => _tsundereMorning,
        TimePeriod.noon => _tsundereNoon,
        TimePeriod.afternoon => _tsundereAfternoon,
        TimePeriod.evening => _tsundereEvening,
        TimePeriod.night => _tsundereNight,
        TimePeriod.lateNight => _tsundereLateNight,
      };

  static List<GreetingTemplate> _getTsundereReunionTemplates(
    ReunionType type,
  ) => switch (type) {
    ReunionType.firstMeet => _tsundereFirstMeet,
    ReunionType.nextDay => _tsundereNextDay,
    ReunionType.longAbsence => _tsundereLongAbsence,
    ReunionType.normal => const [],
  };

  static List<GreetingTemplate> _getGenkiTemplates(TimePeriod period) =>
      switch (period) {
        TimePeriod.earlyMorning => _genkiEarlyMorning,
        TimePeriod.morning => _genkiMorning,
        TimePeriod.noon => _genkiNoon,
        TimePeriod.afternoon => _genkiAfternoon,
        TimePeriod.evening => _genkiEvening,
        TimePeriod.night => _genkiNight,
        TimePeriod.lateNight => _genkiLateNight,
      };

  static List<GreetingTemplate> _getGenkiReunionTemplates(ReunionType type) =>
      switch (type) {
        ReunionType.firstMeet => _genkiFirstMeet,
        ReunionType.nextDay => _genkiNextDay,
        ReunionType.longAbsence => _genkiLongAbsence,
        ReunionType.normal => const [],
      };

  static List<GreetingTemplate> _getOneesanTemplates(TimePeriod period) =>
      switch (period) {
        TimePeriod.earlyMorning => _oneesanEarlyMorning,
        TimePeriod.morning => _oneesanMorning,
        TimePeriod.noon => _oneesanNoon,
        TimePeriod.afternoon => _oneesanAfternoon,
        TimePeriod.evening => _oneesanEvening,
        TimePeriod.night => _oneesanNight,
        TimePeriod.lateNight => _oneesanLateNight,
      };

  static List<GreetingTemplate> _getOneesanReunionTemplates(ReunionType type) =>
      switch (type) {
        ReunionType.firstMeet => _oneesanFirstMeet,
        ReunionType.nextDay => _oneesanNextDay,
        ReunionType.longAbsence => _oneesanLongAbsence,
        ReunionType.normal => const [],
      };

  static List<GreetingTemplate> _getFallbackTemplates(TimePeriod period) =>
      switch (period) {
        TimePeriod.earlyMorning => _fallbackEarlyMorning,
        TimePeriod.morning => _fallbackMorning,
        TimePeriod.noon => _fallbackNoon,
        TimePeriod.afternoon => _fallbackAfternoon,
        TimePeriod.evening => _fallbackEvening,
        TimePeriod.night => _fallbackNight,
        TimePeriod.lateNight => _fallbackLateNight,
      };

  static List<GreetingTemplate> _getFallbackReunionTemplates(
    ReunionType type,
  ) => switch (type) {
    ReunionType.firstMeet => _fallbackFirstMeet,
    ReunionType.nextDay => _fallbackNextDay,
    ReunionType.longAbsence => _fallbackLongAbsence,
    ReunionType.normal => const [],
  };

  /// 替换模板中的 {userTitle} 占位符
  static GreetingTemplate applyUserTitle(
    GreetingTemplate template,
    String userTitle,
  ) {
    return GreetingTemplate(
      text: template.text.replaceAll('{userTitle}', userTitle),
      emotion: template.emotion,
    );
  }
}
