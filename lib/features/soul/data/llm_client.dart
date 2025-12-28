import 'package:dio/dio.dart';
import 'package:waifu/core/utils/logger.dart';

/// LLM 客户端 (兼容 OpenAI/DeepSeek API)
class LLMClient {
  final Dio _dio;
  final String _baseUrl;
  final String _apiKey;
  final String _model;

  LLMClient({
    required String baseUrl,
    required String apiKey,
    String model = 'deepseek-chat',
  })  : _baseUrl = baseUrl,
        _apiKey = apiKey,
        _model = model,
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ));

  /// 发送聊天请求
  Future<String> chat({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int maxTokens = 500,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            ...messages,
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
        },
      );

      final content = response.data['choices'][0]['message']['content'] as String;
      AppLogger.d('LLM Response: $content');
      return content;
    } on DioException catch (e) {
      AppLogger.e('LLM Error', e, e.stackTrace);
      throw LLMException('请求失败: ${e.message}');
    } catch (e) {
      AppLogger.e('LLM Error', e);
      throw LLMException('未知错误: $e');
    }
  }

  void dispose() {
    _dio.close();
  }
}

class LLMException implements Exception {
  final String message;
  LLMException(this.message);

  @override
  String toString() => 'LLMException: $message';
}
