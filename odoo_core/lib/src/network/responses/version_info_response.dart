class VersionInfoResponse {
  const VersionInfoResponse({
    this.serverVersion,
    this.serverVersionInfo,
    this.serverSerie,
    this.protocolVersion,
  });

  final String? serverVersion;
  final List<dynamic>? serverVersionInfo;
  final String? serverSerie;
  final int? protocolVersion;

  factory VersionInfoResponse.fromJson(Map<String, dynamic> json) {
    return VersionInfoResponse(
      serverVersion: json['server_version'] as String?,
      serverVersionInfo: json['server_version_info'] as List<dynamic>?,
      serverSerie: json['server_serie'] as String?,
      protocolVersion: json['protocol_version'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (serverVersion != null) 'server_version': serverVersion,
        if (serverVersionInfo != null) 'server_version_info': serverVersionInfo,
        if (serverSerie != null) 'server_serie': serverSerie,
        if (protocolVersion != null) 'protocol_version': protocolVersion,
      };
}
