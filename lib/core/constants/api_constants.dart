/// API endpoint and model constants used across the app.
class ApiConstants {
  ApiConstants._();

  // Moonshot AI (Kimi) configuration
  static const String moonshotBaseUrl = 'https://api.moonshot.ai/v1';
  static const String chatCompletionsPath = '/chat/completions';

  static const String modelAnalyst = 'kimi-k2.6';
  static const String modelThinking = 'kimi-k2.6';
  static const String modelEngineer = 'kimi-k2.7-code';
  static const String modelFixer = 'kimi-k2.7-code';

  static const double temperatureAnalyst = 0.7;
  static const double temperatureThinking = 0.3;
  static const double temperatureEngineer = 0.2;
  static const double temperatureFixer = 0.2;

  static const int maxTokens = 4096;

  // Vercel configuration
  static const String vercelBaseUrl = 'https://api.vercel.com';
  static const String vercelDeploymentsPath = '/v13/deployments';

  // Networking
  static const Duration requestTimeout = Duration(seconds: 60);
  static const int maxRetries = 2;
  static const int maxAutoFixAttempts = 5;
}
