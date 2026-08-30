import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:lumi/core/utils/logger.dart';

class LLMTokenUsage {
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;

  const LLMTokenUsage({
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
  });
}

class LLMChatResponse {
  final String content;
  final String? reasoningContent; // 思维链内容
  final LLMTokenUsage usage;

  const LLMChatResponse({
    required this.content,
    this.reasoningContent,
    required this.usage,
  });
}

/// 流式事件类型
enum LLMStreamEventType {
  thinking, // 思考内容 delta
  content, // 回复内容 delta
  done, // 流结束
  error, // 流出错
}

/// 流式事件
class LLMStreamEvent {
  final LLMStreamEventType type;
  final String delta; // 本次增量文本
  final LLMTokenUsage? usage; // 仅 done 时携带

  const LLMStreamEvent({required this.type, this.delta = '', this.usage});
}

// LLM 客户端 (兼容 OpenAI/DeepSeek API)
class LLMClient {
  final Dio _dio;
  final String _baseUrl;
  final String _apiKey;
  final String _model;

  LLMClient({
    required String baseUrl,
    required String apiKey,
    String model = 'deepseek-v4-flash',
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
  Future<LLMChatResponse> chat({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int maxTokens = 500,
    double topP = 1.0,
    bool enableSearch = false,
    bool enableThinking = true,
    String reasoningEffort = 'high',
  }) async {
    try {
      final requestData = _buildRequestData(
        systemPrompt: systemPrompt,
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
        topP: topP,
        enableSearch: enableSearch,
        enableThinking: enableThinking,
        reasoningEffort: reasoningEffort,
      );

      AppLogger.d(
        'LLM Request: model=$_model, temp=$temperature, maxTokens=$maxTokens, topP=$topP, thinking=$enableThinking, reasoningEffort=$reasoningEffort, search=$enableSearch',
      );

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
      final usage = response.data['usage'] as Map<String, dynamic>?;

      // 支持思考模式的模型会返回 reasoning_content 和 content
      // 普通模型只返回 content
      String content;
      String? reasoning;
      if (message['reasoning_content'] != null) {
        content = message['content'] as String? ?? '';
        reasoning = message['reasoning_content'] as String?;
        if (reasoning != null && reasoning.isNotEmpty) {
          AppLogger.d(
            'LLM Reasoning: ${reasoning.substring(0, reasoning.length > 200 ? 200 : reasoning.length)}...',
          );
        }
      } else {
        content = message['content'] as String;
      }

      AppLogger.d('LLM Response: $content');
      return LLMChatResponse(
        content: content,
        reasoningContent: reasoning,
        usage: LLMTokenUsage(
          promptTokens: _readUsageToken(usage, 'prompt_tokens'),
          completionTokens: _readUsageToken(usage, 'completion_tokens'),
          totalTokens: _readUsageToken(usage, 'total_tokens'),
        ),
      );
    } on DioException catch (e) {
      // 尝试去除思考参数
      if (enableThinking && e.response?.statusCode == 400) {
        AppLogger.w('检测到不支持的思考参数，正在重试');
        return chat(
          systemPrompt: systemPrompt,
          messages: messages,
          enableThinking: false,
          enableSearch: enableSearch,
          temperature: temperature,
          maxTokens: maxTokens,
          topP: topP,
          reasoningEffort: reasoningEffort,
        );
      }
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
          enableSearch: false,
          enableThinking: enableThinking,
          reasoningEffort: reasoningEffort,
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

  // 流式聊天请求，返回 `Stream<LLMStreamEvent>`
  Stream<LLMStreamEvent> chatStream({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int maxTokens = 500,
    double topP = 1.0,
    bool enableSearch = false,
    bool enableThinking = true,
    String reasoningEffort = 'high',
  }) async* {
    try {
      final requestData = _buildRequestData(
        systemPrompt: systemPrompt,
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
        topP: topP,
        enableSearch: enableSearch,
        enableThinking: enableThinking,
        reasoningEffort: reasoningEffort,
        stream: true,
      );

      AppLogger.d('LLM Stream Request: model=$_model, stream=true');

      final response = await _dio.post<ResponseBody>(
        '$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream,
        ),
        data: requestData,
      );

      // 解析 SSE 流
      final stream = response.data!.stream;
      final buffer = StringBuffer();
      LLMTokenUsage? finalUsage;

      await for (final chunk in stream) {
        buffer.write(utf8.decode(chunk));

        // SSE 行以 \n\n 分隔
        while (buffer.toString().contains('\n\n')) {
          final raw = buffer.toString();
          final idx = raw.indexOf('\n\n');
          final eventBlock = raw.substring(0, idx);
          buffer.clear();
          buffer.write(raw.substring(idx + 2));

          for (final line in eventBlock.split('\n')) {
            if (!line.startsWith('data: ')) continue;
            final data = line.substring(6).trim();

            // 流结束标记
            if (data == '[DONE]') {
              yield LLMStreamEvent(
                type: LLMStreamEventType.done,
                usage: finalUsage,
              );
              return;
            }

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final choices = json['choices'] as List?;

              // 提取 usage（部分 API 在最后一个 chunk 返回）
              if (json['usage'] != null) {
                final u = json['usage'] as Map<String, dynamic>;
                finalUsage = LLMTokenUsage(
                  promptTokens: _readUsageToken(u, 'prompt_tokens'),
                  completionTokens: _readUsageToken(u, 'completion_tokens'),
                  totalTokens: _readUsageToken(u, 'total_tokens'),
                );
              }

              if (choices == null || choices.isEmpty) continue;
              final delta = choices[0]['delta'] as Map<String, dynamic>? ?? {};

              // DeepSeek 思考内容 delta
              final reasoningDelta =
                  delta['reasoning_content'] as String? ?? '';
              if (reasoningDelta.isNotEmpty) {
                yield LLMStreamEvent(
                  type: LLMStreamEventType.thinking,
                  delta: reasoningDelta,
                );
              }

              // 正文内容 delta
              final contentDelta = delta['content'] as String? ?? '';
              if (contentDelta.isNotEmpty) {
                yield LLMStreamEvent(
                  type: LLMStreamEventType.content,
                  delta: contentDelta,
                );
              }
            } catch (_) {
              // 跳过无法解析的行
            }
          }
        }
      }

      // 如果 buffer 里还有残留数据，尝试处理
      if (buffer.isNotEmpty) {
        for (final line in buffer.toString().split('\n')) {
          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6).trim();
          if (data == '[DONE]') break;
        }
      }

      // 没收到 [DONE] 也正常结束
      yield LLMStreamEvent(type: LLMStreamEventType.done, usage: finalUsage);
    } on DioException catch (e) {
      AppLogger.e('LLM Stream DioError: ${e.type} - ${e.message}');
      yield LLMStreamEvent(
        type: LLMStreamEventType.error,
        delta: '流式请求失败: ${e.message}',
      );
    } catch (e, st) {
      AppLogger.e('LLM Stream Error', e, st);
      yield LLMStreamEvent(type: LLMStreamEventType.error, delta: '流式未知错误: $e');
    }
  }

  /// 构建请求体（chat 和 chatStream 共用）
  Map<String, dynamic> _buildRequestData({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    required double temperature,
    required int maxTokens,
    required double topP,
    required bool enableSearch,
    required bool enableThinking,
    required String reasoningEffort,
    bool stream = false,
  }) {
    final requestMessages = <Map<String, dynamic>>[];
    if (systemPrompt.trim().isNotEmpty) {
      requestMessages.add({'role': 'system', 'content': systemPrompt});
    }
    requestMessages.addAll(messages);

    final requestData = <String, dynamic>{
      'model': _model,
      'messages': requestMessages,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'top_p': topP,
    };

    if (stream) {
      requestData['stream'] = true;
      // 请求在流式模式下也返回 usage（OpenAI 兼容）
      requestData['stream_options'] = {'include_usage': true};
    }

    if (enableThinking) {
      requestData['thinking'] = {'type': 'enabled'};
      requestData['reasoning_effort'] = reasoningEffort;
    }

    final modelLower = _model.toLowerCase();
    if (enableSearch) {
      final isSupported =
          (modelLower.contains('qwen') ||
              modelLower.contains('deepseek') ||
              modelLower.contains('abab') ||
              modelLower.contains('minimax')) &&
          !modelLower.contains('glm');
      if (isSupported) {
        requestData['enable_search'] = true;
        requestData['search_options'] = {'forced_search': true};
      }
    }

    return requestData;
  }

  static Future<List<String>> fetchModels({
    required String baseUrl,
    required String apiKey,
  }) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    try {
      var url = baseUrl.trim();
      if (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }
      final response = await dio.get(
        '$url/models',
        options: Options(
          headers: {
            if (apiKey.trim().isNotEmpty)
              'Authorization': 'Bearer ${apiKey.trim()}',
          },
        ),
      );
      final data = response.data;
      final List<String> modelIds = [];
      if (data is Map && data['data'] is List) {
        for (final item in data['data']) {
          if (item is Map && item['id'] != null) {
            final id = item['id'].toString().trim();
            if (id.isNotEmpty) modelIds.add(id);
          }
        }
      } else if (data is Map && data['models'] is List) {
        for (final item in data['models']) {
          if (item is Map) {
            final name = item['name'] ?? item['id'] ?? item['model'];
            if (name != null && name.toString().trim().isNotEmpty) {
              modelIds.add(name.toString().trim());
            }
          }
        }
      } else if (data is List) {
        for (final item in data) {
          if (item is Map && item['id'] != null) {
            modelIds.add(item['id'].toString().trim());
          } else if (item is String && item.trim().isNotEmpty) {
            modelIds.add(item.trim());
          }
        }
      }
      final result = modelIds.toSet().toList()..sort();
      return result;
    } on DioException catch (e) {
      AppLogger.e('Fetch models failed: ${e.message}');
      throw LLMException(
        '获取模型列表失败: ${e.response?.statusCode ?? ''} ${e.message}',
      );
    } finally {
      dio.close();
    }
  }

  int? _readUsageToken(Map<String, dynamic>? usage, String key) {
    final value = usage?[key];
    if (value is num) return value.toInt();
    return int.tryParse('$value');
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
