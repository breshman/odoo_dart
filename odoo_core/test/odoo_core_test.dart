import 'package:test/test.dart';
import 'package:odoo_core/odoo_core.dart';

// 1. Mock the client for testing to respect clean architecture
class MockOdooClient implements OdooClient {
  @override
  Future<dynamic> callKwRaw({
    required String model,
    required String method,
    List args = const [],
    Map<String, dynamic> kwargs = const {},
  }) async {
    if (method == 'web_search_read') {
      return {
        'records': [
          {'id': 1, 'name': 'John Doe', 'active': true, 'create_uid': [2, 'Admin']},
        ],
        'length': 1,
      };
    } else if (method == 'create') {
      return 99; // Mock new ID
    }
    return {};
  }
}

// 2. Dummy Model to test the repository parsing
class DummyEmployee extends OdooBaseModel {
  DummyEmployee({
    required super.id,
    required super.name,
    required super.active,
    super.createUid,
  });

  static DummyEmployee fromJson(Map<String, dynamic> json) {
    final base = OdooBaseModel.baseFromJson(json);
    return DummyEmployee(
      id: base.id,
      name: base.name,
      active: base.active,
      createUid: base.createUid,
    );
  }
}

// 3. Dummy Repository simulating a generated class
class DummyEmployeeRepository extends OdooRepository<DummyEmployee> {
  DummyEmployeeRepository(OdooClient client)
      : super(
          client: client,
          modelName: 'hr.employee',
          specification: {'id': {}, 'name': {}},
          fromJson: DummyEmployee.fromJson,
        );
}

void main() {
  group('A group of Repository tests', () {
    final client = MockOdooClient();
    final repo = DummyEmployeeRepository(client);

    test('searchFetch decodes properly using MockOdooClient', () async {
      final res = await repo.searchFetch();
      expect(res.records, isNotEmpty);
      expect(res.length, equals(1));
      
      final emp = res.records.first;
      expect(emp.name, equals('John Doe'));
      expect(emp.createUid, equals(2)); // Verifying the parsed many2one ID
    });

    test('create returns correct integer from Mock', () async {
      final newId = await repo.create({'name': 'John Doe'});
      expect(newId, equals(99));
    });
  });
}
