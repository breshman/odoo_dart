// ============================================================
//  odoo_session.dart
//  Modelo inmutable de sesión Odoo con soporte multi-versión.
// ============================================================

/// Representa una empresa dentro de la sesión de Odoo.
class OdooCompany {
  const OdooCompany({required this.id, required this.name});

  final int id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  static OdooCompany fromJson(Map<String, dynamic> json) {
    return OdooCompany(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  static List<OdooCompany> fromJsonList(List<dynamic> list) =>
      list.map((e) => OdooCompany.fromJson(e as Map<String, dynamic>)).toList();

  @override
  bool operator ==(Object other) =>
      other is OdooCompany && id == other.id && name == other.name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'OdooCompany(id: $id, name: $name)';
}

/// Representa una sesión autenticada con un servidor Odoo.
///
/// Es **inmutable** y serializable (`fromJson`/`toJson`) para que pueda
/// almacenarse localmente (Hive, SharedPreferences, etc.) y restaurarse
/// sin necesidad de re-autenticar.
///
/// ## Creación
/// - [OdooSession.fromSessionInfo] — a partir de la respuesta de `/web/session/authenticate`.
/// - [OdooSession.fromJson] — a partir de JSON previamente guardado.
///
/// ## Ejemplo
/// ```dart
/// final session = await odooClient.authenticate('mydb', 'admin', 'admin');
/// print(session.userName);           // "Administrator"
/// print(session.serverVersionInt);  // 18
/// print(session.isAuthenticated);   // true
/// ```
class OdooSession {
  const OdooSession({
    required this.id,
    required this.userId,
    required this.partnerId,
    required this.companyId,
    required this.allowedCompanies,
    required this.userName,
    required this.userLogin,
    required this.userLang,
    required this.userTz,
    required this.isSystem,
    required this.dbName,
    required this.serverVersion,
    this.websocketWorkerVersion = '1',
    this.csrfToken = '',
  });

  /// El valor de la cookie `session_id`.
  final String id;

  /// ID del usuario en la base de datos.
  final int userId;

  /// ID del partner vinculado al usuario.
  final int partnerId;

  /// ID de la empresa activa del usuario.
  final int companyId;

  /// Lista de empresas a las que tiene acceso el usuario (Odoo 13+).
  final List<OdooCompany> allowedCompanies;

  /// Nombre completo del usuario.
  final String userName;

  /// Login del usuario (e.g. "admin").
  final String userLogin;

  /// Código de idioma del usuario (e.g. "es_MX", "en_US").
  final String userLang;

  /// Zona horaria del usuario (e.g. "America/Mexico_City").
  final String userTz;

  /// `true` si el usuario es un usuario interno del sistema.
  final bool isSystem;

  /// Nombre de la base de datos Odoo.
  final String dbName;

  /// Versión mayor del servidor Odoo como string (e.g. "18", "17").
  final String serverVersion;

  /// Ejemplo: `'18.0-7'`, `'17.0-3'`
  final String websocketWorkerVersion;

  /// Token CSRF para la sesión actual.
  ///
  /// Requerido para peticiones de tipo "http" (como carga de archivos).
  /// Se obtiene de la respuesta de `/web/session/authenticate` o `/web/session/info`.
  final String csrfToken;

  // ── Getters ────────────────────────────────────────────────

  /// Versión mayor del servidor Odoo como entero. Útil para lógica condicional:
  /// ```dart
  /// final imageField = session.serverVersionInt >= 13 ? 'image_128' : 'image_small';
  /// ```
  int get serverVersionInt {
    final sanitized = serverVersion.length == 1
        ? serverVersion
        : serverVersion.substring(serverVersion.length - 2);
    return int.tryParse(sanitized) ?? -1;
  }

  /// `true` si la sesión tiene un `userId` válido (> 0).
  ///
  /// No requiere que `id` esté presente porque en algunos servidores Odoo
  /// (RunBot, instancias legacy) el `session_id` llega solo vía cookie HTTP
  /// y no en el body de la respuesta.
  bool get isAuthenticated => userId > 0;

  // ── Factories ──────────────────────────────────────────────

  /// Crea una [OdooSession] a partir del objeto `result` de `/web/session/authenticate`.
  ///
  /// Compatible con Odoo 12–18+. Maneja los distintos formatos de
  /// `user_companies` a lo largo de las versiones.
  static OdooSession fromSessionInfo(Map<String, dynamic> info) {
    final ctx = info['user_context'] as Map<String, dynamic>? ?? {};

    // Versión del servidor
    List<dynamic> versionInfo = [18];
    if (info.containsKey('server_version_info')) {
      versionInfo = info['server_version_info'] as List<dynamic>;
    }

    // Empresa activa y empresas permitidas (multi-versión)
    int companyId = info['company_id'] as int? ?? 0;
    final List<OdooCompany> allowedCompanies = [];

    if (info.containsKey('user_companies') &&
        info['user_companies'] is! bool) {
      final userCompanies =
          info['user_companies'] as Map<String, dynamic>;
      final currentCompany = userCompanies['current_company'];

      if (currentCompany is List) {
        // Odoo 12–14: [id, name]
        companyId = currentCompany[0] as int? ?? 0;
      } else if (currentCompany is int) {
        // Odoo 15+: id directo
        companyId = currentCompany;
      }

      final sessionAllowed = userCompanies['allowed_companies'];
      if (sessionAllowed is Map) {
        // Odoo 15+: {'1': {'id': 1, 'name': '...'}, ...}
        for (final e in sessionAllowed.values) {
          final eMap = e as Map<String, dynamic>;
          allowedCompanies.add(
            OdooCompany(
              id: eMap['id'] as int,
              name: eMap['name'] as String,
            ),
          );
        }
      } else if (sessionAllowed is List) {
        // Odoo 13–14: [[id, name], ...]
        for (final e in sessionAllowed) {
          allowedCompanies.add(
            OdooCompany(id: e[0] as int, name: e[1] as String),
          );
        }
      }
    }

    return OdooSession(
      id: info['session_id'] as String? ?? info['id'] as String? ?? '',
      userId: info['uid'] as int? ?? 0,
      partnerId: info['partner_id'] as int? ?? 0,
      companyId: companyId,
      allowedCompanies: allowedCompanies,
      userName: info['name'] as String? ?? '',
      userLogin: info['username'] as String? ?? '',
      userLang: ctx['lang'] as String? ?? 'en_US',
      userTz: ctx['tz'] is String ? ctx['tz'] as String : 'UTC',
      isSystem: info['is_system'] as bool? ?? false,
      dbName: info['db'] as String? ?? '',
      serverVersion: versionInfo[0].toString(),
      websocketWorkerVersion:
          info['websocket_worker_version']?.toString() ?? '1',
      csrfToken: info['csrf_token'] as String? ?? '',
    );
  }

  /// Restaura una [OdooSession] desde JSON previamente guardado con [toJson].
  static OdooSession fromJson(Map<String, dynamic> json) {
    return OdooSession(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as int? ?? 0,
      partnerId: json['partnerId'] as int? ?? 0,
      companyId: json['companyId'] as int? ?? 0,
      allowedCompanies: OdooCompany.fromJsonList(
        json['allowedCompanies'] as List<dynamic>? ?? [],
      ),
      userName: json['userName'] as String? ?? '',
      userLogin: json['userLogin'] as String? ?? '',
      userLang: json['userLang'] as String? ?? 'en_US',
      userTz: json['userTz'] as String? ?? 'UTC',
      isSystem: json['isSystem'] as bool? ?? false,
      dbName: json['dbName'] as String? ?? '',
      serverVersion: json['serverVersion']?.toString() ?? '18',
      websocketWorkerVersion:
          json['websocketWorkerVersion']?.toString() ?? '1',
      csrfToken: json['csrfToken'] as String? ?? '',
    );
  }

  // ── Serialización ──────────────────────────────────────────

  /// Convierte la sesión a JSON para persistirla localmente.
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'partnerId': partnerId,
        'companyId': companyId,
        'allowedCompanies':
            allowedCompanies.map((c) => c.toJson()).toList(),
        'userName': userName,
        'userLogin': userLogin,
        'userLang': userLang,
        'userTz': userTz,
        'isSystem': isSystem,
        'dbName': dbName,
        'serverVersion': serverVersion,
        'websocketWorkerVersion': websocketWorkerVersion,
        'csrfToken': csrfToken,
      };

  // ── Manipulación ───────────────────────────────────────────

  /// Retorna una copia de la sesión con el `id` actualizado.
  /// Cuando `newId` es vacío, resetea todos los campos de usuario (logout).
  OdooSession updateSessionId(String newId) {
    final loggedOut = newId.isEmpty;
    return OdooSession(
      id: newId,
      userId: loggedOut ? 0 : userId,
      partnerId: loggedOut ? 0 : partnerId,
      companyId: loggedOut ? 0 : companyId,
      allowedCompanies: loggedOut ? [] : allowedCompanies,
      userName: loggedOut ? '' : userName,
      userLogin: loggedOut ? '' : userLogin,
      userLang: loggedOut ? '' : userLang,
      userTz: loggedOut ? '' : userTz,
      isSystem: loggedOut ? false : isSystem,
      dbName: loggedOut ? '' : dbName,
      serverVersion: loggedOut ? '' : serverVersion,
      websocketWorkerVersion: loggedOut ? '1' : websocketWorkerVersion,
      csrfToken: loggedOut ? '' : csrfToken,
    );
  }

  /// Retorna una copia de la sesión con el `csrfToken` actualizado.
  OdooSession updateCsrfToken(String newToken) {
    return OdooSession(
      id: id,
      userId: userId,
      partnerId: partnerId,
      companyId: companyId,
      allowedCompanies: allowedCompanies,
      userName: userName,
      userLogin: userLogin,
      userLang: userLang,
      userTz: userTz,
      isSystem: isSystem,
      dbName: dbName,
      serverVersion: serverVersion,
      websocketWorkerVersion: websocketWorkerVersion,
      csrfToken: newToken,
    );
  }

  @override
  String toString() =>
      'OdooSession{userId: $userId, userName: $userName, '
      'userLogin: $userLogin, db: $dbName, v: $serverVersion}';
}
