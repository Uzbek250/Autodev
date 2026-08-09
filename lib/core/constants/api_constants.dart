/// API endpoint and model constants used across the app.
class ApiConstants {
  ApiConstants._();

  // DeepSeek API (OpenAI-compatible)
  static const String deepSeekBaseUrl = 'https://api.deepseek.com/v1';
  static const String chatCompletionsPath = '/chat/completions';

  // DeepSeek currently exposes these OpenAI-compatible chat models.
  static const String modelAnalyst = 'deepseek-chat';
  static const String modelThinking = 'deepseek-chat';
  static const String modelEngineer = 'deepseek-chat';
  static const String modelFixer = 'deepseek-chat';

  static const double temperatureAnalyst = 0.7;
  static const double temperatureThinking = 0.3;
  static const double temperatureEngineer = 0.2;
  static const double temperatureFixer = 0.2;

  static const int maxTokens = 16000;

  // Vercel configuration
  static const String vercelBaseUrl = 'https://api.vercel.com';
  static const String vercelDeploymentsPath = '/v13/deployments';

  // Networking
  static const Duration requestTimeout = Duration(seconds: 60);
  static const int maxRetries = 2;
  static const int maxAutoFixAttempts = 5;
}
