/// Excepción base para todos los errores del servidor Odoo.
///
/// ## Factory constructors semánticos
/// - [OdooException.accessDenied] — error 403, acceso denegado.
/// - [OdooException.notFound] — error 404, registro no encontrado.
/// - [OdooException.serverError] — error 500, fallo interno del servidor.
///
/// ## Subclases
/// - [OdooSessionExpiredException] — lanzada automáticamente cuando el servidor
///   retorna código 100 (sesión expirada o no válida).
class OdooException implements Exception {
  const OdooException({
    required this.code,
    required this.message,
    this.data,
  });

  final int code;
  final String message;
  final Map<String, dynamic>? data;

  // ── Factory constructors semánticos ────────────────────────

  /// Error 403: el usuario no tiene permisos para realizar la operación.
  factory OdooException.accessDenied([String? detail]) => OdooException(
        code: 403,
        message: detail ?? 'Access Denied',
      );

  /// Error 404: el registro solicitado no existe.
  factory OdooException.notFound([String? detail]) => OdooException(
        code: 404,
        message: detail ?? 'Record not found',
      );

  /// Error 500: fallo interno del servidor Odoo.
  factory OdooException.serverError([String? detail]) => OdooException(
        code: 500,
        message: detail ?? 'Internal Server Error',
      );

  /// Crea una [OdooException] a partir del objeto `error` de la respuesta JSON-RPC.
  /// Extrae el mensaje detallado de `data.message` si está disponible.
  factory OdooException.fromJson(Map<String, dynamic> json) {
    final String smartMessage = (json['data']?['message'] as String?) ??
        (json['message'] as String?) ??
        'Unknown Odoo error';

    return OdooException(
      code: json['code'] as int? ?? 0,
      message: smartMessage,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  // ── Getters ────────────────────────────────────────────────

  /// `true` si el error indica un problema de autenticación o sesión.
  /// Incluye código 100 (sesión expirada) y 403 (acceso denegado).
  bool get isAuthError => code == 100 || code == 403;

  // ── Serialización ──────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        if (data != null) 'data': data,
      };

  @override
  String toString() =>
      'OdooException(code: $code, message: $message, data: $data)';
}

/// Lanzada automáticamente por [OdooRpcService] cuando el servidor retorna
/// código de error **100**, lo que indica que la sesión expiró o no es válida.
///
/// Úsala para redirigir al usuario a la pantalla de login:
/// ```dart
/// try {
///   await repo.searchFetch();
/// } on OdooSessionExpiredException {
///   // Navegar a LoginPage
/// }
/// ```
class OdooSessionExpiredException extends OdooException {
  const OdooSessionExpiredException({String? message})
      : super(
          code: 100,
          message: message ?? 'Session expired or not valid',
        );

  @override
  String toString() =>
      'OdooSessionExpiredException(message: $message)';
}
