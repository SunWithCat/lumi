# Live2D JNI 相关类不混淆
-keep class com.sunwithcat.waifu.live2d.** { *; }

# 保留 JNI 方法
-keepclasseswithmembernames class * {
    native <methods>;
}

# 保留 @JvmStatic 注解的方法
-keepclassmembers class * {
    @kotlin.jvm.JvmStatic *;
}
