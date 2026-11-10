import 'package:odoo_core/odoo_core.dart';
import 'package:test/test.dart';

enum SamplePartnerFields {
  id,
  displayName,
  isCompany,
  partnerLatitude,
}

void main() {
  group('OdooDomain & DomainTerm Tests', () {
    test('Enum extensions automatically convert camelCase to snake_case field names', () {
      final condIsCompany = SamplePartnerFields.isCompany.equals(true);
      expect(condIsCompany.toOdoo(), equals(['is_company', '=', true]));

      final condDisplayName = SamplePartnerFields.displayName.ilike('Azure');
      expect(condDisplayName.toOdoo(), equals(['display_name', 'ilike', 'Azure']));

      final condLatitude = SamplePartnerFields.partnerLatitude.greaterThan(40.5);
      expect(condLatitude.toOdoo(), equals(['partner_latitude', '>', 40.5]));
    });
    test('Condition compiles to standard Odoo tuple', () {
      final cond = Domain.equals('is_company', true);
      expect(cond.toOdoo(), equals(['is_company', '=', true]));

      final condIlike = Domain.ilike('name', 'azure');
      expect(condIlike.toOdoo(), equals(['name', 'ilike', 'azure']));

      final condIn = Domain.inList('id', [1, 2, 3]);
      expect(condIn.toOdoo(), equals(['id', 'in', [1, 2, 3]]));
    });

    test('String extensions produce typed conditions correctly', () {
      final condEq = 'state'.equals('done');
      expect(condEq.toOdoo(), equals(['state', '=', 'done']));

      final condGt = 'quantity'.greaterThan(10);
      expect(condGt.toOdoo(), equals(['quantity', '>', 10]));

      final condLte = 'qty_done'.lessOrEqual(5);
      expect(condLte.toOdoo(), equals(['qty_done', '<=', 5]));

      final condIlike = 'barcode'.ilike('AZURE%');
      expect(condIlike.toOdoo(), equals(['barcode', 'ilike', 'AZURE%']));

      final condIn = 'category_id'.inList([10, 20]);
      expect(condIn.toOdoo(), equals(['category_id', 'in', [10, 20]]));
    });

    test('Domain.or with 2 terms generates single prefix pipe', () {
      final orTerm = Domain.or([
        'name'.equals('Admin'),
        'name'.ilike('demo'),
      ]);

      expect(
        orTerm.toOdoo(),
        equals([
          '|',
          ['name', '=', 'Admin'],
          ['name', 'ilike', 'demo'],
        ]),
      );
    });

    test('Domain.or with 3 terms generates Polish prefix notation', () {
      final orTerm = Domain.or([
        'name'.equals('A'),
        'name'.equals('B'),
        'name'.equals('C'),
      ]);

      expect(
        orTerm.toOdoo(),
        equals([
          '|',
          '|',
          ['name', '=', 'A'],
          ['name', '=', 'B'],
          ['name', '=', 'C'],
        ]),
      );
    });

    test('Domain.not wraps term with negation', () {
      final notTerm = Domain.not('active'.equals(false));
      expect(
        notTerm.toOdoo(),
        equals([
          '!',
          ['active', '=', false],
        ]),
      );
    });

    test('Complex nested domain compiles accurately', () {
      final complex = Domain.or([
        'name'.equals('Special'),
        Domain.and([
          'active'.equals(true),
          'qty'.greaterThan(0),
        ]),
      ]);

      expect(
        complex.toOdoo(),
        equals([
          '|',
          ['name', '=', 'Special'],
          ['active', '=', true],
          ['qty', '>', 0],
        ]),
      );
    });

    test('resolveOdooDomain handles terms, lists of terms, and raw lists', () {
      // 1. Single term
      final single = Domain.equals('id', 42);
      expect(resolveOdooDomain(single), equals([['id', '=', 42]]));

      // 2. OrTerm
      final orTerm = Domain.or(['a'.equals(1), 'b'.equals(2)]);
      expect(resolveOdooDomain(orTerm), equals(['|', ['a', '=', 1], ['b', '=', 2]]));

      // 3. List of terms
      final listTerms = [
        'is_company'.equals(true),
        'customer_rank'.greaterThan(0),
      ];
      expect(
        resolveOdooDomain(listTerms),
        equals([
          ['is_company', '=', true],
          ['customer_rank', '>', 0],
        ]),
      );

      // 4. Raw list (backward compatibility)
      final raw = [
        '|',
        ['name', '=', 'Test'],
        ['name', 'ilike', 'Test'],
      ];
      expect(resolveOdooDomain(raw), equals(raw));

      // 5. Null or empty
      expect(resolveOdooDomain(null), equals([]));
      expect(resolveOdooDomain(const []), equals([]));
    });
  });
}
