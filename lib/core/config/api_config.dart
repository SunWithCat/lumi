/// API 配置
/// 
/// 从本地配置文件读取，api_config.local.dart 已被 gitignore
import 'api_config.local.dart';

class ApiConfig {
  static const baseUrl = 'https://api.deepseek.com/v1';
  static const model = 'deepseek-chat';
  
  // 从本地文件读取 key
  static const apiKey = LocalApiConfig.apiKey;

  static bool get isConfigured => apiKey.isNotEmpty;
}
