import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/error/failures.dart';
import '../../../core/utils/json_extractor.dart';
import '../../../domain/entities/project_entity.dart';

/// Raw HTTP datasource for Moonshot AI (Kimi) API.
/// Throws [ServerException] / [NetworkException] / [ParsingException].
class KimiRemoteDatasource {
  final Dio _dio;

  KimiRemoteDatasource({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConstants.moonshotBaseUrl,
              connectTimeout: ApiConstants.requestTimeout,
              receiveTimeout: ApiConstants.requestTimeout,
              sendTimeout: ApiConstants.requestTimeout,
            ));

  Future<String> _chatCompletion({
    required String model,
    required double temperature,
    required String systemPrompt,
    required String userContent,
    required String apiKey,
  }) async {
    Exception? lastException;
    for (var attempt = 0; attempt <= ApiConstants.maxRetries; attempt++) {
      try {
        final response = await _dio.post(
          ApiConstants.chatCompletionsPath,
          options: Options(headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          }),
          data: jsonEncode({
            'model': model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userContent},
            ],
            'temperature': temperature,
            'max_tokens': ApiConstants.maxTokens,
          }),
        );

        final data = response.data as Map<String, dynamic>;
        final choices = data['choices'] as List?;
        if (choices == null || choices.isEmpty) {
          throw ServerException('AI javob bermadi (bo\'sh choices)');
        }
        final content =
            (choices.first as Map<String, dynamic>)['message']['content']
                    as String? ??
                '';
        return content;
      } on DioException catch (e) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          lastException = NetworkException(
              'Ulanish vaqti tugadi. Internet aloqasini tekshiring.');
          if (attempt < ApiConstants.maxRetries) {
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
        } else if (e.response?.statusCode == 429) {
          lastException =
              ServerException('API cheklovi. Biroz kuting va qaytadan urining.');
          await Future.delayed(Duration(seconds: 5 * (attempt + 1)));
          continue;
        } else if (e.response?.statusCode == 401) {
          throw ServerException('Noto\'g\'ri API kalit. Sozlamalarda tekshiring.');
        } else if (e.type == DioExceptionType.unknown &&
            e.error?.toString().contains('SocketException') == true) {
          lastException =
              NetworkException('Internet aloqasi yo\'q. Qayta ulanib, urining.');
          if (attempt < ApiConstants.maxRetries) {
            await Future.delayed(const Duration(seconds: 3));
            continue;
          }
        } else {
          throw ServerException(
              'Server xatosi: ${e.response?.statusCode} - ${e.message}');
        }
      }
    }
    if (lastException is NetworkException) {
      throw lastException!;
    }
    throw lastException ?? ServerException('Noma\'lum xato yuz berdi');
  }

  Future<AnalystOutputEntity> runAnalyst({
    required String userIdea,
    required String apiKey,
  }) async {
    final raw = await _chatCompletion(
      model: ApiConstants.modelAnalyst,
      temperature: ApiConstants.temperatureAnalyst,
      systemPrompt: AgentPrompts.analyst,
      userContent: userIdea,
      apiKey: apiKey,
    );

    final json = JsonExtractor.tryExtractObject(raw);
    if (json == null) {
      throw ParsingException(
          'Analyst javobi JSON formatida emas. Xom javob:\n${raw.substring(0, raw.length.clamp(0, 500))}');
    }
    return AnalystOutputEntity.fromJson(json);
  }

  Future<ProductSpecEntity> runThinking({
    required String userIdea,
    required AnalystOutputEntity analystOutput,
    required String apiKey,
  }) async {
    final userContent =
        'Foydalanuvchi g\'oyasi:\n$userIdea\n\nAnalitik natija:\n${jsonEncode(analystOutput.toJson())}';

    final raw = await _chatCompletion(
      model: ApiConstants.modelThinking,
      temperature: ApiConstants.temperatureThinking,
      systemPrompt: AgentPrompts.thinking,
      userContent: userContent,
      apiKey: apiKey,
    );

    final json = JsonExtractor.tryExtractObject(raw);
    if (json == null) {
      throw ParsingException(
          'Thinking javobi JSON formatida emas. Xom javob:\n${raw.substring(0, raw.length.clamp(0, 500))}');
    }
    return ProductSpecEntity.fromJson(json);
  }

  Future<String> generateFile({
    required ProductSpecEntity spec,
    required SpecFile file,
    required Map<String, String> previousFiles,
    required String apiKey,
  }) async {
    final prevFilesContext = previousFiles.isEmpty
        ? 'Hali hech qanday fayl yaratilmagan.'
        : previousFiles.entries
            .map((e) => '// ===== ${e.key} =====\n${e.value}')
            .join('\n\n');

    final userContent = '''
Project spec (JSON):
${jsonEncode(spec.toJson())}

Current file to generate:
Path: ${file.path}
Language: ${file.language}
Description: ${file.description}

Previously generated files (for import context):
$prevFilesContext
''';

    final raw = await _chatCompletion(
      model: ApiConstants.modelEngineer,
      temperature: ApiConstants.temperatureEngineer,
      systemPrompt: AgentPrompts.engineer,
      userContent: userContent,
      apiKey: apiKey,
    );

    return JsonExtractor.stripCodeFences(raw);
  }

  Future<String> fixFile({
    required String filePath,
    required String currentCode,
    required String errorMessage,
    required String apiKey,
  }) async {
    final userContent = '''
File path: $filePath

Current broken code:
$currentCode

Error:
$errorMessage

Output the complete corrected file content only.
''';

    final raw = await _chatCompletion(
      model: ApiConstants.modelFixer,
      temperature: ApiConstants.temperatureFixer,
      systemPrompt: AgentPrompts.fixer,
      userContent: userContent,
      apiKey: apiKey,
    );

    return JsonExtractor.stripCodeFences(raw);
  }
}
