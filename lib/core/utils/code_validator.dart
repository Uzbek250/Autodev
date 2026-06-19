/// Lightweight syntax validation used by the auto-fix loop.
///
/// This is intentionally heuristic (brace/paren/bracket/quote balance) since
/// running a real compiler/linter for arbitrary generated languages is out
/// of scope for an on-device mobile app. It catches the most common
/// generation errors (truncated output, unbalanced blocks) cheaply.
class CodeValidator {
  CodeValidator._();

  static ValidationResult validate(String code, String language) {
    if (code.trim().isEmpty) {
      return const ValidationResult(isValid: false, error: 'File is empty');
    }

    final braceCheck = _checkBalanced(code, '{', '}');
    if (!braceCheck.isValid) return braceCheck;

    final parenCheck = _checkBalanced(code, '(', ')');
    if (!parenCheck.isValid) return parenCheck;

    final bracketCheck = _checkBalanced(code, '[', ']');
    if (!bracketCheck.isValid) return bracketCheck;

    if (_looksLikePlaceholder(code)) {
      return const ValidationResult(
        isValid: false,
        error: 'Generated code contains unresolved placeholders/TODOs',
      );
    }

    return const ValidationResult(isValid: true);
  }

  static ValidationResult _checkBalanced(String code, String open, String close) {
    final cleaned = _stripStringsAndComments(code);
    var depth = 0;
    for (final rune in cleaned.runes) {
      final ch = String.fromCharCode(rune);
      if (ch == open) depth++;
      if (ch == close) depth--;
      if (depth < 0) {
        return ValidationResult(
          isValid: false,
          error: 'Unbalanced "$open$close" - unexpected "$close"',
        );
      }
    }
    if (depth != 0) {
      return ValidationResult(
        isValid: false,
        error: 'Unbalanced "$open$close" - $depth unclosed',
      );
    }
    return const ValidationResult(isValid: true);
  }

  static String _stripStringsAndComments(String code) {
    final buffer = StringBuffer();
    var inString = false;
    String? stringChar;
    var inLineComment = false;
    var inBlockComment = false;

    for (var i = 0; i < code.length; i++) {
      final ch = code[i];
      final next = i + 1 < code.length ? code[i + 1] : '';

      if (inLineComment) {
        if (ch == '\n') inLineComment = false;
        continue;
      }
      if (inBlockComment) {
        if (ch == '*' && next == '/') {
          inBlockComment = false;
          i++;
        }
        continue;
      }
      if (inString) {
        if (ch == '\\') {
          i++;
          continue;
        }
        if (ch == stringChar) {
          inString = false;
          stringChar = null;
        }
        continue;
      }

      if (ch == '/' && next == '/') {
        inLineComment = true;
        i++;
        continue;
      }
      if (ch == '/' && next == '*') {
        inBlockComment = true;
        i++;
        continue;
      }
      if (ch == '"' || ch == "'" || ch == '`') {
        inString = true;
        stringChar = ch;
        continue;
      }

      buffer.write(ch);
    }
    return buffer.toString();
  }

  static bool _looksLikePlaceholder(String code) {
    final lower = code.toLowerCase();
    return lower.contains('// todo') ||
        lower.contains('# todo') ||
        lower.contains('implement later') ||
        lower.contains('your code here');
  }
}

class ValidationResult {
  final bool isValid;
  final String? error;
  const ValidationResult({required this.isValid, this.error});
}
