// Modified version of Cookie class
// from https://github.com/dart-lang/sdk/blob/master/sdk/lib/_http/http_headers.dart
// Thanks to BSD-3 License we can take and modify original code.
//
// Since http headers parsing code is not shared between dart:io and browser,
// and since we want to keep this library compatible with both web and backend,
// we avoid importing Cookie from dart:io and use our own RFC-6265-compliant
// implementation instead.

/// Representa una cookie HTTP parseada desde un header `Set-Cookie`.
///
/// Uso típico dentro de [OdooRpcService]:
/// ```dart
/// final raw = response.headers['set-cookie'] ?? [];
/// final cookies = raw.map(OdooCookie.fromSetCookieValue).toList();
/// final sessionCookie = cookies.firstWhere((c) => c.name == 'session_id');
/// print(sessionCookie.value); // "abc123..."
/// ```
class OdooCookie {
  String _name;
  String _value;

  String? expires;
  int? maxAge;
  String? domain;
  String? _path;
  bool httpOnly = false;
  bool secure = false;

  OdooCookie(String name, String value)
      : _name = _validateName(name),
        _value = _validateValue(value),
        httpOnly = true;

  /// Parsea un header `Set-Cookie` completo siguiendo RFC 6265.
  ///
  /// ```dart
  /// final cookie = OdooCookie.fromSetCookieValue(
  ///   'session_id=abc123; Path=/; HttpOnly; SameSite=Lax',
  /// );
  /// print(cookie.name);  // session_id
  /// print(cookie.value); // abc123
  /// ```
  OdooCookie.fromSetCookieValue(String value)
      : _name = '',
        _value = '' {
    _parseSetCookieValue(value);
  }

  String get name => _name;
  String get value => _value;
  String? get path => _path;

  set path(String? newPath) {
    _validatePath(newPath);
    _path = newPath;
  }

  set name(String newName) {
    _validateName(newName);
    _name = newName;
  }

  set value(String newValue) {
    _validateValue(newValue);
    _value = newValue;
  }

  /// Parsea todos los campos del header `Set-Cookie` según RFC 6265.
  void _parseSetCookieValue(String s) {
    var index = 0;

    bool done() => index == s.length;

    String parseName() {
      final start = index;
      while (!done()) {
        if (s[index] == '=') break;
        index++;
      }
      return s.substring(start, index).trim();
    }

    String parseValue() {
      final start = index;
      while (!done()) {
        if (s[index] == ';') break;
        index++;
      }
      return s.substring(start, index).trim();
    }

    void parseAttributes() {
      String parseAttributeName() {
        final start = index;
        while (!done()) {
          if (s[index] == '=' || s[index] == ';') break;
          index++;
        }
        return s.substring(start, index).trim().toLowerCase();
      }

      String parseAttributeValue() {
        final start = index;
        while (!done()) {
          if (s[index] == ';') break;
          index++;
        }
        return s.substring(start, index).trim().toLowerCase();
      }

      while (!done()) {
        final attrName = parseAttributeName();
        var attrValue = '';
        if (!done() && s[index] == '=') {
          index++; // skip '='
          attrValue = parseAttributeValue();
        }
        switch (attrName) {
          case 'expires':
            expires = attrValue;
          case 'max-age':
            maxAge = int.tryParse(attrValue);
          case 'domain':
            domain = attrValue;
          case 'path':
            path = attrValue;
          case 'httponly':
            httpOnly = true;
          case 'secure':
            secure = true;
        }
        if (!done()) index++; // skip ';'
      }
    }

    _name = _validateName(parseName());
    if (done() || _name.isEmpty) {
      throw FormatException('Failed to parse Set-Cookie header: [$s]');
    }
    index++; // skip '='
    _value = _validateValue(parseValue());
    if (done()) return;
    index++; // skip ';'
    parseAttributes();
  }

  /// Extrae el valor de `session_id` de una lista de headers `Set-Cookie`.
  ///
  /// Retorna el valor de la cookie (sin prefijo) o `null` si no se encontró.
  ///
  /// ```dart
  /// final sessionId = OdooCookie.extractSessionId(
  ///   response.headers['set-cookie'] ?? [],
  /// );
  /// ```
  static String? extractSessionId(List<String> rawCookies) {
    for (final raw in rawCookies) {
      try {
        final cookie = OdooCookie.fromSetCookieValue(raw);
        if (cookie.name == 'session_id' && cookie.value.isNotEmpty) {
          return cookie.value;
        }
      } catch (_) {
        // Si falla el parse de esta cookie, continúa con la siguiente
      }
    }
    return null;
  }

  @override
  String toString() {
    final sb = StringBuffer()
      ..write(_name)
      ..write('=')
      ..write(_value);
    if (expires != null) sb.write('; Expires=$expires');
    if (maxAge != null) sb.write('; Max-Age=$maxAge');
    if (domain != null) sb.write('; Domain=$domain');
    if (_path != null) sb.write('; Path=$_path');
    if (secure) sb.write('; Secure');
    if (httpOnly) sb.write('; HttpOnly');
    return sb.toString();
  }

  static String _validateName(String newName) {
    const separators = [
      '(',
      ')',
      '<',
      '>',
      '@',
      ',',
      ';',
      ':',
      '\\',
      '"',
      '/',
      '[',
      ']',
      '?',
      '=',
      '{',
      '}'
    ];
    for (var i = 0; i < newName.length; i++) {
      final codeUnit = newName.codeUnitAt(i);
      if (codeUnit <= 32 || codeUnit >= 127 || separators.contains(newName[i])) {
        throw FormatException(
          "Invalid character in cookie name, code unit: '$codeUnit'",
          newName,
          i,
        );
      }
    }
    return newName;
  }

  static String _validateValue(String newValue) {
    // RFC 6265: las comillas dobles rodeando el valor son válidas
    var start = 0;
    var end = newValue.length;
    if (end >= 2 &&
        newValue.codeUnitAt(start) == 0x22 &&
        newValue.codeUnitAt(end - 1) == 0x22) {
      start++;
      end--;
    }
    for (var i = start; i < end; i++) {
      final codeUnit = newValue.codeUnitAt(i);
      if (!(codeUnit == 0x21 ||
          (codeUnit >= 0x23 && codeUnit <= 0x2B) ||
          (codeUnit >= 0x2D && codeUnit <= 0x3A) ||
          (codeUnit >= 0x3C && codeUnit <= 0x5B) ||
          (codeUnit >= 0x5D && codeUnit <= 0x7E))) {
        throw FormatException(
          "Invalid character in cookie value, code unit: '$codeUnit'",
          newValue,
          i,
        );
      }
    }
    return newValue;
  }

  static void _validatePath(String? path) {
    if (path == null) return;
    for (var i = 0; i < path.length; i++) {
      final codeUnit = path.codeUnitAt(i);
      // RFC 6265: semicolons and CTLs not allowed in path
      if (codeUnit < 0x20 || codeUnit >= 0x7F || codeUnit == 0x3B) {
        throw FormatException(
          "Invalid character in cookie path, code unit: '$codeUnit'",
        );
      }
    }
  }
}
