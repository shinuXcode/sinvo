import 'package:flutter_test/flutter_test.dart';
import 'package:sadab_invo/sadab_core/models.dart';

void main() {
  test('product JSON round trip preserves unknown fields', () {
    final p = Product.fromJson({
      'id': 'a', 'name': ' Pen ', 'buyPrice': 2, 'sellPrice': 3.5, 'stock': 4,
      'futureField': 'keep-me',
    });
    expect(p.name, 'Pen');
    expect(p.lowStockThreshold, 5);
    expect(p.toJson()['futureField'], 'keep-me');
  });

  test('invalid products throw FormatException', () {
    final base = {'id': 'a', 'name': 'x', 'buyPrice': 1, 'sellPrice': 1, 'stock': 1};
    expect(() => Product.fromJson({...base, 'name': ' '}), throwsFormatException);
    expect(() => Product.fromJson({...base, 'stock': -1}), throwsFormatException);
    expect(() => Product.fromJson({...base, 'sellPrice': 'x'}), throwsFormatException);
    expect(() => Product.fromJson({...base, 'stock': 1.5}), throwsFormatException);
  });

  test('low stock flag', () {
    final p = Product.fromJson({
      'id': 'a', 'name': 'x', 'buyPrice': 1, 'sellPrice': 1, 'stock': 5,
    });
    expect(p.isLowStock, isTrue);
    expect(p.copyWith(stock: 6).isLowStock, isFalse);
  });
}
