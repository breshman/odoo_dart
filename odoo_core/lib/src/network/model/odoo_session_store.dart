import 'odoo_session.dart';

/// Interfaz para persistencia y almacenamiento de [OdooSession].
///
/// Permite desacoplar la librería del mecanismo de persistencia concreto
/// (como SharedPreferences, flutter_secure_storage, Hive o memoria).
abstract class OdooSessionStore {
  /// Guarda o actualiza la sesión activa.
  Future<void> save(OdooSession session);

  /// Recupera la sesión almacenada, o `null` si no existe.
  Future<OdooSession?> read();

  /// Elimina la sesión almacenada.
  Future<void> clear();
}

/// Implementación en memoria de [OdooSessionStore].
///
/// Ideal para entornos de prueba o aplicaciones donde la sesión no
/// deba persistir tras el cierre del proceso.
class InMemorySessionStore implements OdooSessionStore {
  InMemorySessionStore([this._session]);

  OdooSession? _session;

  @override
  Future<void> save(OdooSession session) async {
    _session = session;
  }

  @override
  Future<OdooSession?> read() async => _session;

  @override
  Future<void> clear() async {
    _session = null;
  }
}
