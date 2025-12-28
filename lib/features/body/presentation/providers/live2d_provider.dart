import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waifu/features/body/presentation/controllers/live2d_controller.dart';

/// Live2D 控制器 Provider
final live2dControllerProvider = Provider<Live2DController>((ref) {
  final controller = Live2DController();
  ref.onDispose(() => controller.dispose());
  return controller;
});
