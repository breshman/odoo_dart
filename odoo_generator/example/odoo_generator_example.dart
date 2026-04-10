import 'package:odoo_annotation/odoo_annotation.dart';
import 'dart:convert';
import 'dart:io';

part 'odoo_generator_example.odoo.g.dart';

/// Modelo: Category (Categoría de productos)
@OdooModel(modelName: 'product.category')
class Category with _$Category {
  @OdooField(type: OdooFieldType.integer, name: 'id')
  final int? id;

  @OdooField(type: OdooFieldType.string, name: 'name')
  final String? name;

  @OdooField(type: OdooFieldType.string, name: 'description')
  final String? description;

  Category({this.id, this.name, this.description});

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}

/// Modelo: Tag (Etiqueta para productos)
@OdooModel(modelName: 'product.tag')
class Tag with _$Tag {
  @OdooField(type: OdooFieldType.integer, name: 'id')
  final int? id;

  @OdooField(type: OdooFieldType.string, name: 'name')
  final String? name;

  @OdooField(type: OdooFieldType.string, name: 'color')
  final String? color;

  Tag({this.id, this.name, this.color});

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
  Map<String, dynamic> toJson() => _$TagToJson(this);
}

/// Modelo: Product (Producto con relaciones)
@OdooModel(modelName: 'product.product')
class Product with _$Product {
  @OdooField(type: OdooFieldType.integer)
  final int? id;

  @OdooField(type: OdooFieldType.string)
  final String? name;

  @OdooField(type: OdooFieldType.string)
  final String? sku;

  @OdooField(type: OdooFieldType.double_)
  final double? price;

  @OdooField(type: OdooFieldType.integer)
  final int? quantity;

  @OdooField(type: OdooFieldType.boolean, name: 'is_active')
  final bool? isActive;

  // many2one: Relación con Category [id, name]
  @OdooField(type: OdooFieldType.many2one, name: 'category_id')
  final List<dynamic>? categoryId;

  @OdooField(type: OdooFieldType.many2one, name: 'category_id')
  final List<Category>? category;

  // many2many: Lista de IDs de Tags
  @OdooField(type: OdooFieldType.many2many, name: 'tag_ids')
  final List<int>? tagIds;

  @OdooField(type: OdooFieldType.datetime, name: 'created_at')
  final DateTime? createdAt;

  @OdooField(type: OdooFieldType.datetime, name: 'updated_at')
  final DateTime? updatedAt;

  Product({
    this.id,
    this.name,
    this.sku,
    this.price,
    this.quantity,
    this.isActive,
    this.categoryId,
    this.category,
    this.tagIds,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}

/// Modelo: ProductLine (Línea de producto - simula detalle de pedido)
@OdooModel(modelName: 'product.line')
class ProductLine with _$ProductLine {
  @OdooField(type: OdooFieldType.integer, name: 'id')
  final int? id;

  // many2one: Relación con Product
  @OdooField(type: OdooFieldType.many2one, name: 'product_id')
  final int? productId;

  @OdooField(type: OdooFieldType.integer, name: 'quantity')
  final int? quantity;

  @OdooField(type: OdooFieldType.double_, name: 'unit_price')
  final double? unitPrice;

  @OdooField(type: OdooFieldType.double_, name: 'subtotal')
  final double? subtotal;

  @OdooField(type: OdooFieldType.string, name: 'notes')
  final String? notes;

  ProductLine({
    this.id,
    this.productId,
    this.quantity,
    this.unitPrice,
    this.subtotal,
    this.notes,
  });

  factory ProductLine.fromJson(Map<String, dynamic> json) => _$ProductLineFromJson(json);
  Map<String, dynamic> toJson() => _$ProductLineToJson(this);
}

/// Modelo: Order (Pedido con relaciones many2many y one2many)
@OdooModel(modelName: 'sale.order')
class Order with _$Order {
  @OdooField(type: OdooFieldType.integer, name: 'id')
  final int? id;

  @OdooField(type: OdooFieldType.string, name: 'name')
  final String? name;

  @OdooField(type: OdooFieldType.date, name: 'order_date')
  final DateTime? orderDate;

  @OdooField(type: OdooFieldType.double_, name: 'total')
  final double? total;

  @OdooField(type: OdooFieldType.string, name: 'status')
  final String? status; // draft, confirmed, shipped, delivered

  // one2many: Lista de líneas de producto
  @OdooField(type: OdooFieldType.one2many, name: 'line_ids')
  final List<int>? lineIds;

  Order({
    this.id,
    this.name,
    this.orderDate,
    this.total,
    this.status,
    this.lineIds,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);
}

/// Función para cargar datos desde JSON
T loadFromJsonFile<T>(String filename, T Function(Map<String, dynamic>) factory) {
  final file = File(filename);
  if (!file.existsSync()) {
    print('❌ Archivo no existe: $filename');
    throw FileSystemException('Archivo no encontrado', filename);
  }
  final jsonString = file.readAsStringSync();
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  return factory(json);
}

void main() {
  print('╔════════════════════════════════════════════════════════════╗');
  print('║ Test: Modelos Relacionados con Datos RPC Odoo              ║');
  print('╚════════════════════════════════════════════════════════════╝\n');
  final file = "test/data";

  // ==================== CREAR JSON DE PRUEBA ====================

  // 1. Crear JSON de Category (con valores faltantes -> false)
  final categoryJson = {
    'id': 1,
    'name': 'Electronics',
    'description': false, // Python RPC retorna false cuando no hay valor
  };
  File('$file/test_category.json').writeAsStringSync(jsonEncode(categoryJson));
  print('✓ Creado: $file/test_category.json');

  // 2. Crear JSON de Tags
  final tag1Json = {
    'id': 1,
    'name': 'Premium',
    'color': '#FF0000',
  };
  final tag2Json = {
    'id': 2,
    'name': 'Sale',
    'color': false, // sin valor
  };
  File('$file/test_tag1.json').writeAsStringSync(jsonEncode(tag1Json));
  File('$file/test_tag2.json').writeAsStringSync(jsonEncode(tag2Json));
  print('✓ Creado: $file/test_tag1.json');
  print('✓ Creado: $file/test_tag2.json');

  // 3. Crear JSON de Product con relaciones
  final productJson = {
    'id': 100,
    'name': 'Laptop Pro M3',
    'sku': 'SKU-LP-M3-2025',
    'price': 1499.99,
    'quantity': 15,
    'is_active': true,
    'category_id': [1, 'Electronics'], // many2one: [id, name]
    'tag_ids': [1, 2], // many2many
    'created_at': '2025-01-15 09:30:00',
    'updated_at': false, // sin fecha de actualización
  };
  File('$file/test_product_complete.json').writeAsStringSync(jsonEncode(productJson));
  print('✓ Creado: $file/test_product_complete.json');

  // 4. Crear JSON de Product con muchos valores false
  final productMinimalJson = {
    'id': 101,
    'name': 'Mystery Product',
    'sku': false,
    'price': false,
    'quantity': false,
    'is_active': false,
    'category_id': false, // many2one sin valor
    'tag_ids': false, // many2many sin valores
    'created_at': '2025-03-23 10:00:00',
    'updated_at': false,
  };
  File('$file/test_product_minimal.json').writeAsStringSync(jsonEncode(productMinimalJson));
  print('✓ Creado: $file/test_product_minimal.json');

  // 5. Crear JSON de ProductLine
  final lineJson = {
    'id': 500,
    'product_id': [100, 'Laptop Pro M3'], // many2one
    'quantity': 2,
    'unit_price': 1499.99,
    'subtotal': 2999.98,
    'notes': false, // sin notas
  };
  File('$file/test_product_line.json').writeAsStringSync(jsonEncode(lineJson));
  print('✓ Creado: $file/test_product_line.json');

  // 6. Crear JSON de Order con relaciones one2many
  final orderJson = {
    'id': 1000,
    'name': 'ORD/2025/00001',
    'order_date': '2025-03-23',
    'total': 2999.98,
    'status': 'confirmed',
    'line_ids': [500, 501], // one2many: lista de ids
  };
  File('$file/test_order.json').writeAsStringSync(jsonEncode(orderJson));
  print('✓ Creado: $file/test_order.json');

  print('\n╔════════════════════════════════════════════════════════════╗');
  print('║ Cargando y Parseando archivos JSON                        ║');
  print('╚════════════════════════════════════════════════════════════╝\n');

  // ==================== CARGAR Y PARSEAR ====================

  try {
    // Cargar Category
    print('📦 Cargando Category...');
    final category = loadFromJsonFile('$file/test_category.json', Category.fromJson);

    print(category.toString());
    print('  id: ${category.id}');
    print('  name: ${category.name}');
    print('  description: ${category.description} (null porque RPC retornó false)\n');

    // Cargar Tags
    print('🏷️  Cargando Tags...');
    final tag1 = loadFromJsonFile('$file/test_tag1.json', Tag.fromJson);
    final tag2 = loadFromJsonFile('$file/test_tag2.json', Tag.fromJson);
    print('  Tag1: ${tag1.name} color=${tag1.color}');
    print('  Tag2: ${tag2.name} color=${tag2.color} (null porque RPC retornó false)\n');

    // Cargar Product completo
    print('🛍️  Cargando Product (COMPLETO)...');
    final productComplete = loadFromJsonFile('$file/test_product_complete.json', Product.fromJson);
    print('  id: ${productComplete.id}');
    print('  name: ${productComplete.name}');
    print('  sku: ${productComplete.sku}');
    print('  price: ${productComplete.price}');
    print('  quantity: ${productComplete.quantity}');
    print('  isActive: ${productComplete.isActive}');
    print('  categoryId: ${productComplete.categoryId} (many2one)');
    print('  tagIds: ${productComplete.tagIds} (many2many)');
    print('  updatedAt: ${productComplete.updatedAt} (null porque RPC retornó false)\n');

    // Cargar Product minimal
    print('🛍️  Cargando Product (MINIMAL - con muchos false)...');
    final productMinimal = loadFromJsonFile('$file/test_product_minimal.json', Product.fromJson);
    print('  id: ${productMinimal.id}');
    print('  name: ${productMinimal.name}');
    print('  sku: ${productMinimal.sku} (null)');
    print('  price: ${productMinimal.price} (null)');
    print('  quantity: ${productMinimal.quantity} (null)');
    print('  isActive: ${productMinimal.isActive} (null)');
    print('  categoryId: ${productMinimal.categoryId} (null - many2one)');
    print('  tagIds: ${productMinimal.tagIds?.isEmpty ?? true ? "[]" : productMinimal.tagIds}');
    print('  createdAt: ${productMinimal.createdAt}');
    print('  updatedAt: ${productMinimal.updatedAt} (null)\n');

    // Cargar ProductLine
    print('📋 Cargando ProductLine...');
    final line = loadFromJsonFile('$file/test_product_line.json', ProductLine.fromJson);
    print('  id: ${line.id}');
    print('  productId: ${line.productId} (many2one)');
    print('  quantity: ${line.quantity}');
    print('  unitPrice: ${line.unitPrice}');
    print('  subtotal: ${line.subtotal}');
    print('  notes: ${line.notes} (null)\n');

    // Cargar Order
    print('📦 Cargando Order...');
    final order = loadFromJsonFile('$file/test_order.json', Order.fromJson);
    print('  id: ${order.id}');
    print('  name: ${order.name}');
    print('  orderDate: ${order.orderDate}');
    print('  total: ${order.total}');
    print('  status: ${order.status}');
    print('  lineIds: ${order.lineIds} (one2many)\n');

    // ==================== CONVERTIR DE VUELTA A JSON ====================

    print('╔════════════════════════════════════════════════════════════╗');
    print('║ Convirtiendo modelos de vuelta a JSON (toJson)          ║');
    print('╚════════════════════════════════════════════════════════════╝\n');

    // Product completo -> JSON
    final productCompleteJson = productComplete.toJson();
    File('$file/output_product_complete.json').writeAsStringSync(jsonEncode(productCompleteJson));
    print('✓ Generado: $file/output_product_complete.json');
    print('  Contenido: ${jsonEncode(productCompleteJson)}\n');

    // Product minimal -> JSON
    final productMinimalJson = productMinimal.toJson();
    File('$file/output_product_minimal.json').writeAsStringSync(jsonEncode(productMinimalJson));
    print('✓ Generado: $file/output_product_minimal.json');
    print('  Contenido: ${jsonEncode(productMinimalJson)}\n');

    // Order -> JSON
    final orderJson2 = order.toJson();
    File('$file/output_order.json').writeAsStringSync(jsonEncode(orderJson2));
    print('✓ Generado: $file/output_order.json');
    print('  Contenido: ${jsonEncode(orderJson2)}\n');

    print('╔════════════════════════════════════════════════════════════╗');
    print('║ ✓ Todos los tests completados exitosamente              ║');
    print('╚════════════════════════════════════════════════════════════╝');
  } catch (e) {
    print('❌ Error: $e');
  }
}
