import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waifu/app.dart';
import 'package:waifu/core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化日志
  AppLogger.init();
  AppLogger.i('Project Waifu starting...');
  
  runApp(
    const ProviderScope(
      child: WaifuApp(),
    ),
  );
}
