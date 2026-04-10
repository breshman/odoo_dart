class OdooException implements Exception {
  const OdooException({
    required this.code,
    required this.message,
    this.data,
  });

  final int code;
  final String message;
  final Map<String, dynamic>? data;

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

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        if (data != null) 'data': data,
      };

  @override
  String toString() {
    return 'OdooException(code: $code, message: $message, data: $data)';
  }
}
