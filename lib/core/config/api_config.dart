import 'api_config.local.dart';

class ApiConfig {
  static const baseUrl = 'https://api.deepseek.com/v1';
  static const model = 'deepseek-reasoner';
  
  // 从本地文件读取 key
  static const apiKey = LocalApiConfig.apiKey;

  static bool get isConfigured => apiKey.isNotEmpty;
}
