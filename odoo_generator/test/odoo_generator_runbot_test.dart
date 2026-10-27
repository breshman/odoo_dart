import 'dart:io';

import 'package:odoo_core/odoo_core.dart';
import 'package:test/test.dart';

import '../example/odoo_generator_example.dart';

const _runbotBaseUrl = 'https://130072570-19-0-all.runbot157.odoo.com';
const _runbotDatabase = '130072570-19-0-all';
final _runbotEnabled = Platform.environment['ODOO_RUNBOT_TEST'] == 'true';

void main() {
  group(
    'ProductLine RunBot integration',
    skip: _runbotEnabled
        ? false
        : 'Set ODOO_RUNBOT_TEST=true to enable the RunBot integration test.',
    () {
      test('builds specification and fetches product.line records', () async {
        final login = Platform.environment['ODOO_RUNBOT_USER'];
        final password = Platform.environment['ODOO_RUNBOT_PASS'];
        expect(login, isNotNull, reason: 'Set ODOO_RUNBOT_USER.');
        expect(password, isNotNull, reason: 'Set ODOO_RUNBOT_PASS.');

        final client = OdooRpcService.standalone()..setBaseUrl(_runbotBaseUrl);

        await client.authenticate(_runbotDatabase, login!, password!);

        try {
          final specification = ProductLineRepository.buildSpecification(
            only: [ProductLineFields.id, ProductLineFields.name],
          ).build();
          final repository = ProductLineRepository(client: client);
          final result = await repository.searchFetch(
            specification: specification,
            limit: 1,
          );

          expect(result.records, hasLength(lessThanOrEqualTo(1)));
          expect(result.records, everyElement(isA<ProductLine>()));
        } finally {
          await client.destroySession();
        }
      });
    },
  );
}
