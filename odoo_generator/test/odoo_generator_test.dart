import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

// Importamos el ejemplo real con modelos generados.
import '../example/odoo_generator_example.dart';

void main() {
  group('Pruebas automáticas de Odoo Generator', () {
    test('Product.fromJson y Product.toJson (false -> null / null -> false)', () {
      final file = File('test/data/test_product_complete.json');
      final rpcJson = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final product = Product.fromJson(rpcJson);

      expect(product.id, equals(100));
      expect(product.name, equals('Laptop Pro M3'));
      expect(product.isActive, equals(true));
      expect(product.categoryId, equals([1, 'Electronics']));
      expect(product.tagIds, equals([1, 2]));
      expect(product.updatedAt, isNull);

      final outputJson = product.toJson();
      expect(outputJson['is_active'], equals(true));
      expect(outputJson.containsKey('updated_at'), isFalse);
    });

    test("test_product_minimal.json", () {
      final file = File('test/data/test_product_minimal.json');

      final restored = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(restored['is_active'], equals(false));
      expect(restored['updated_at'], equals(false));

      // file.deleteSync();
    });

    test('Category carga desde JSON con campo false', () {
      final file = File('test/data/test_category.json');
      final categoryJson = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final category = Category.fromJson(categoryJson);

      expect(category.description, isNull);
      expect(category.name, isNotNull);
      expect(category.name, isA<String>());

      final output = category.toJson();
      expect(output.containsKey('description'), isFalse);
    });

    group('Pruebas de métodos generados (toJson, toString, copyWith, specification, modelName)',
        () {
      test('Category: toString, copyWith, specification, modelName', () {
        final cat = Category(id: 1, name: 'Electronics', description: 'Gadgets');

        // toString
        expect(
            cat.toString(), contains('Category(id: 1, name: Electronics, description: Gadgets)'));

        // copyWith
        final cat2 = cat.copyWith(name: 'Updated');
        expect(cat2.name, 'Updated');
        expect(cat2.id, 1);

        // specification (static extension member)
        expect($CategorySpecExtension.specification, contains('id'));
        expect($CategorySpecExtension.specification, contains('name'));

        // modelName (static extension member)
        expect($CategoryModelExtension.modelName, 'product.category');
      });

      test('Product: copyWith mantiene otros campos y crea nueva instancia', () {
        final prod = Product(id: 1, name: 'Test', price: 10.0);
        final prod2 = prod.copyWith(price: 20.0);

        expect(prod2.id, 1);
        expect(prod2.name, 'Test');
        expect(prod2.price, 20.0);
        expect(identical(prod, prod2), isFalse);
      });

      test('Product: toJson solo incluye campos con valor', () {
        final prod = Product(id: 1, name: 'Test');
        final json = prod.toJson();

        expect(json['id'], 1);
        expect(json['name'], 'Test');
        expect(json.containsKey('sku'), isFalse);
        expect(json.containsKey('price'), isFalse);
      });

      test('Tag: toString y specification', () {
        final tag = Tag(id: 5, name: 'Premium', color: '#ff0000');
        expect(tag.toString(), contains('Tag(id: 5, name: Premium, color: #ff0000)'));
        expect($TagSpecExtension.specification, contains('color'));
      });
    });
  });
}
