import 'package:dio/dio.dart';
import 'package:lumi/core/utils/logger.dart';

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
  }) : _baseUrl = baseUrl,
       _apiKey = apiKey,
       _model = model,
       _dio = Dio(
         BaseOptions(
           connectTimeout: const Duration(seconds: 30),
           receiveTimeout: const Duration(seconds: 120), // 推理模型需要更长时间
         ),
       );

  /// 发送聊天请求
  /// [temperature] 0.0-2.0, 越高越随机/创意
  /// [maxTokens] 最大输出 token 数，越大回复越长
  /// [topP] 0.0-1.0, nucleus sampling
  /// [enableSearch] 设置是否联网
  Future<String> chat({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int maxTokens = 500,
    double topP = 1.0,
    bool enableSearch = false,
  }) async {
    try {
      // deepseek-reasoner 不支持 temperature 和 max_tokens
      final isReasonerModel = _model.toLowerCase().contains('reasoner');
      final requestMessages = <Map<String, dynamic>>[];
      if (systemPrompt.trim().isNotEmpty) {
        requestMessages.add({'role': 'system', 'content': systemPrompt});
      }
      requestMessages.addAll(messages);

      final requestData = <String, dynamic>{
        'model': _model,
        'messages': requestMessages,
      };

      // 只有非推理模型才添加这些参数
      if (!isReasonerModel) {
        requestData['temperature'] = temperature;
        requestData['max_tokens'] = maxTokens;
        requestData['top_p'] = topP;
      }

      // 某些模型不支持 enable_search 参数，如果强制传递会导致 400 错误
      // 这里可以根据模型名称做简单的黑/白名单过滤，或者干脆在这里先简单处理
      final modelLower = _model.toLowerCase();
      if (enableSearch) {
        // 白名单：Qwen, DeepSeek(百炼版), MiniMax 支持 enable_search
        // 排除：GLM 已确认在百炼接口下不支持联网
        final isSupported =
            (modelLower.contains('qwen') ||
             modelLower.contains('deepseek') ||
             modelLower.contains('abab') ||
             modelLower.contains('minimax')) &&
            !modelLower.contains('glm');

        if (isSupported) {
          requestData['enable_search'] = true;
          requestData['search_options'] = {'forced_search': true};
          
          // 如果是新版 Qwen 模型，理论上支持思考模式，但暂不开启以防 400
          // if (modelLower.contains('qwen3')) { requestData['enable_thinking'] = true; }
        }
      }

      AppLogger.d(
        'LLM Request: model=$_model, temp=$temperature, maxTokens=$maxTokens, topP=$topP',
      );
      AppLogger.d('LLM URL: $_baseUrl/chat/completions');
      AppLogger.d('LLM Request Data: $requestData');

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

      AppLogger.d('LLM Response status: ${response.statusCode}');

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
          AppLogger.d(
            'LLM Reasoning: ${reasoning.substring(0, reasoning.length > 200 ? 200 : reasoning.length)}...',
          );
        }
      } else {
        content = message['content'] as String;
      }

      AppLogger.d('LLM Response: $content');
      return content;
    } on DioException catch (e) {
      // 触发了自动降级逻辑
      if (enableSearch &&
          e.response?.statusCode == 400 &&
          e.response?.data.toString().contains('enable_search') == true) {
        AppLogger.w(
          'Detected unsupported enable_search, retrying without it...',
        );
        return chat(
          systemPrompt: systemPrompt,
          messages: messages,
          temperature: temperature,
          maxTokens: maxTokens,
          topP: topP,
          enableSearch: false, // 强制关闭再试一次！
        );
      }

      AppLogger.e('LLM DioError: ${e.type} - ${e.message}');
      if (e.response != null) {
        AppLogger.e(
          'LLM Response: ${e.response?.statusCode} - ${e.response?.data}',
        );
      }
      throw LLMException('请求失败: ${e.message}');
    } catch (e, st) {
      AppLogger.e('LLM Error', e, st);
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
