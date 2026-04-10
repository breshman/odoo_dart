class RpcPayload<T> {
  const RpcPayload({
    required this.id,
    required this.jsonrpc,
    required this.method,
    required this.params,
  });

  final String id;
  final String jsonrpc;
  final String method;
  final T params;

  factory RpcPayload.from({
    required T params,
    required String id,
  }) =>
      RpcPayload(
        id: id,
        jsonrpc: '2.0',
        method: 'call',
        params: params,
      );

  factory RpcPayload.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return RpcPayload<T>(
      id: json['id'] as String? ?? '',
      jsonrpc: json['jsonrpc'] as String? ?? '2.0',
      method: json['method'] as String? ?? 'call',
      params: fromJsonT(json['params']),
    );
  }

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) {
    return {
      'id': id,
      'jsonrpc': jsonrpc,
      'method': method,
      'params': toJsonT(params),
    };
  }
}

class EmptyBody {
  const EmptyBody();

  factory EmptyBody.fromJson(Map<String, dynamic> json) => const EmptyBody();
  Map<String, dynamic> toJson() => {};
}
