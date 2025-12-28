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
          receiveTimeout: const Duration(seconds: 120), // 推理模型需要更长时间
        ));

  /// 发送聊天请求
  Future<String> chat({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int maxTokens = 500,
  }) async {
    try {
      // deepseek-reasoner 不支持 temperature 和 max_tokens
      final isReasonerModel = _model.contains('reasoner');
      
      final requestData = <String, dynamic>{
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          ...messages,
        ],
      };
      
      // 只有非推理模型才添加这些参数
      if (!isReasonerModel) {
        requestData['temperature'] = temperature;
        requestData['max_tokens'] = maxTokens;
      }
      
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );

      final choice = response.data['choices'][0];
      final message = choice['message'];
      
      // deepseek-reasoner 模型会返回 reasoning_content 和 content
      // 普通模型只返回 content
      String content;
      if (message['reasoning_content'] != null) {
        // R1 推理模型：content 是最终答案
        content = message['content'] as String? ?? '';
        final reasoning = message['reasoning_content'] as String?;
        if (reasoning != null && reasoning.isNotEmpty) {
          AppLogger.d('LLM Reasoning: ${reasoning.substring(0, reasoning.length > 200 ? 200 : reasoning.length)}...');
        }
      } else {
        content = message['content'] as String;
      }
      
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
