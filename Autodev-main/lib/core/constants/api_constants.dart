/// API endpoint and model constants used across the app.
class ApiConstants {
  ApiConstants._();

  // DeepSeek API configuration (OpenAI-compatible)
  static const String moonshotBaseUrl = 'https://api.deepseek.com/v1';
  static const String chatCompletionsPath = '/chat/completions';

  static const String modelAnalyst = 'deepseek-v4-flash';
  static const String modelThinking = 'deepseek-v4-flash';
  static const String modelEngineer = 'deepseek-v4-flash';
  static const String modelFixer = 'deepseek-v4-flash';

  static const double temperatureAnalyst = 0.7;
  static const double temperatureThinking = 0.3;
  static const double temperatureEngineer = 0.2;
  static const double temperatureFixer = 0.2;

  // Was 4096 — too low for the Engineer/Fixer agents, which caused
  // truncated files on anything beyond a small file. Files that get
  // cut off mid-way fail the brace-balance check in CodeValidator and
  // then loop through the (equally truncated) fixer, wasting retries.
  static const int maxTokens = 16000;

  // Vercel configuration
  static const String vercelBaseUrl = 'https://api.vercel.com';
  static const String vercelDeploymentsPath = '/v13/deployments';

  // Networking
  static const Duration requestTimeout = Duration(seconds: 60);
  static const int maxRetries = 2;
  static const int maxAutoFixAttempts = 5;
}
