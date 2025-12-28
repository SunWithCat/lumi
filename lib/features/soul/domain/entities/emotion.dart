/// 情感类型
enum EmotionType {
  happy,
  sad,
  angry,
  surprised,
  shy,
  curious,
  neutral,
  loving,
  worried;

  String get emoji => switch (this) {
    happy => '😊',
    sad => '😢',
    angry => '😠',
    surprised => '😲',
    shy => '😳',
    curious => '🤔',
    neutral => '😐',
    loving => '🥰',
    worried => '😟',
  };

  String get label => switch (this) {
    happy => 'Happy',
    sad => 'Sad',
    angry => 'Angry',
    surprised => 'Surprised',
    shy => 'Shy',
    curious => 'Curious',
    neutral => 'Neutral',
    loving => 'Loving',
    worried => 'Worried',
  };

  /// 从 LLM 返回的标签解析情感
  static EmotionType fromTag(String tag) {
    final lower = tag.toLowerCase().replaceAll(RegExp(r'[\[\]]'), '');
    return EmotionType.values.firstWhere(
      (e) => e.name == lower,
      orElse: () => EmotionType.neutral,
    );
  }
}
