import 'dart:convert';

/// Utility for safely extracting a JSON object from an LLM's raw text response.
///
/// LLMs sometimes wrap JSON in markdown fences or add stray prose around it,
/// even when instructed not to. This helper tries progressively more
/// aggressive strategies before giving up.
class JsonExtractor {
  JsonExtractor._();

  /// Attempts to parse [raw] as JSON. Returns null if no valid JSON object
  /// could be extracted.
  static Map<String, dynamic>? tryExtractObject(String raw) {
    final candidates = <String>[
      raw.trim(),
      _stripMarkdownFences(raw),
      _extractBetweenBraces(raw),
    ];

    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      try {
        final decoded = jsonDecode(candidate);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static String _stripMarkdownFences(String input) {
    var result = input.trim();
    if (result.startsWith('```')) {
      result = result.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
    }
    if (result.endsWith('```')) {
      result = result.substring(0, result.length - 3);
    }
    return result.trim();
  }

  static String _extractBetweenBraces(String input) {
    final start = input.indexOf('{');
    final end = input.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return '';
    return input.substring(start, end + 1);
  }

  /// Strips markdown code fences from a raw code response (e.g. ```jsx ... ```)
  /// in case the Engineer/Fixer agent ignores the "no fences" instruction.
  static String stripCodeFences(String raw) {
    var result = raw.trim();
    final fenceRegex = RegExp(r'^```[a-zA-Z0-9]*\n([\s\S]*?)\n```$');
    final match = fenceRegex.firstMatch(result);
    if (match != null) {
      return match.group(1)?.trim() ?? result;
    }
    if (result.startsWith('```')) {
      result = result.replaceFirst(RegExp(r'^```[a-zA-Z0-9]*\n?'), '');
      if (result.endsWith('```')) {
        result = result.substring(0, result.length - 3);
      }
    }
    return result.trim();
  }
}
