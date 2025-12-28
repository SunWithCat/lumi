import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lumi/core/utils/logger.dart';

/// Live2D 控制器
class Live2DController extends ChangeNotifier {
  static const _channel = MethodChannel('com.sunwithcat.lumi/live2d');
  static const _eventChannel = EventChannel('com.sunwithcat.lumi/live2d/events');

  int? _textureId;
  bool _isInitialized = false;
  bool _isModelLoaded = false;
  StreamSubscription? _eventSubscription;

  final _motionFinishedController = StreamController<MotionEvent>.broadcast();

  int? get textureId => _textureId;
  bool get isInitialized => _isInitialized;
  bool get isModelLoaded => _isModelLoaded;
  Stream<MotionEvent> get onMotionFinished => _motionFinishedController.stream;

  /// 初始化渲染器
  Future<bool> initialize({required int width, required int height}) async {
    if (_isInitialized) return true;

    try {
      final result = await _channel.invokeMethod<Map>('initialize', {
        'width': width,
        'height': height,
      });

      if (result != null && result['textureId'] != null) {
        _textureId = result['textureId'] as int;
        _isInitialized = true;
        _subscribeEvents();
        AppLogger.i('Live2D initialized, textureId: $_textureId');
        notifyListeners();
        return true;
      }
    } on PlatformException catch (e) {
      AppLogger.e('Live2D init failed', e);
    }
    return false;
  }

  /// 加载模型
  Future<bool> loadModel(String assetPath) async {
    if (!_isInitialized) return false;

    try {
      final success = await _channel.invokeMethod<bool>('loadModel', {
        'path': assetPath,
      });
      _isModelLoaded = success == true;
      AppLogger.i('Live2D model loaded: $_isModelLoaded');
      notifyListeners();
      return _isModelLoaded;
    } on PlatformException catch (e) {
      AppLogger.e('Load model failed', e);
      return false;
    }
  }

  /// 播放动作
  Future<void> playMotion(String group, {int index = 0, int priority = 2}) async {
    AppLogger.i('playMotion called: $group[$index] priority=$priority, isModelLoaded=$_isModelLoaded');
    if (!_isModelLoaded) {
      AppLogger.w('playMotion: model not loaded, skipping');
      return;
    }

    try {
      await _channel.invokeMethod('playMotion', {
        'group': group,
        'index': index,
        'priority': priority,
      });
      AppLogger.i('playMotion: method invoked successfully');
    } on PlatformException catch (e) {
      AppLogger.e('Play motion failed', e);
    }
  }

  /// 设置表情
  Future<void> setExpression(String expressionId) async {
    if (!_isModelLoaded) return;

    try {
      await _channel.invokeMethod('setExpression', {
        'expressionId': expressionId,
      });
    } on PlatformException catch (e) {
      AppLogger.e('Set expression failed', e);
    }
  }

  /// 触摸测试
  Future<String?> hitTest(double x, double y) async {
    if (!_isModelLoaded) return null;

    try {
      final result = await _channel.invokeMethod<String>('hitTest', {
        'x': x,
        'y': y,
      });
      return result?.isEmpty == true ? null : result;
    } on PlatformException catch (e) {
      AppLogger.e('Hit test failed', e);
      return null;
    }
  }

  /// 设置视线跟随
  Future<void> setLookAt(double x, double y) async {
    if (!_isModelLoaded) return;

    try {
      await _channel.invokeMethod('setLookAt', {'x': x, 'y': y});
    } on PlatformException catch (e) {
      AppLogger.e('Set lookAt failed', e);
    }
  }

  void _subscribeEvents() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          final type = event['type'] as String?;
          if (type == 'motionFinished') {
            _motionFinishedController.add(MotionEvent(
              group: event['group'] as String,
              index: event['index'] as int,
            ));
          }
        }
      },
      onError: (e) => AppLogger.e('Event stream error', e),
    );
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _motionFinishedController.close();
    _channel.invokeMethod('destroy');
    super.dispose();
  }
}

class MotionEvent {
  final String group;
  final int index;
  MotionEvent({required this.group, required this.index});
}
