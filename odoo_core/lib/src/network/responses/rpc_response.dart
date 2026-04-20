import '../exceptions/odoo_exception.dart';

class RpcResponse<T> {
  const RpcResponse({
    required this.jsonrpc,
    required this.result,
    this.id,
    this.error,
  });

  final String jsonrpc;
  final String? id;
  final T? result;
  final OdooException? error;

  factory RpcResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return RpcResponse<T>(
      jsonrpc: json['jsonrpc'] as String? ?? '2.0',
      id: json['id']?.toString(),
      result: json['result'] != null ? fromJsonT(json['result']) : null,
      error: json['error'] != null
          ? OdooException.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      if (result != null) 'result': toJsonT(result as T),
      if (error != null) 'error': error?.toJson(),
    };
  }
}
