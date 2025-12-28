import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumi/app.dart';
import 'package:lumi/core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化日志
  AppLogger.init();
  AppLogger.i('Project Lumi starting...');
  
  runApp(
    const ProviderScope(
      child: LumiApp(),
    ),
  );
}
