import 'package:flutter_test/flutter_test.dart';
import 'package:sadab_invo/sadab_core/stock.dart';

import 'helpers.dart';

void main() {
  test('receive increases stock and records purchase', () {
    final p = mk('a', stock: 2, buy: 5);
    final r = StockService.receive(
        product: p, qty: 10, unitCost: 6, purchaseId: 'p1');
    expect(r.product.stock, 12);
    expect(r.product.buyPrice, 6);
    expect(r.purchase.total, 60);
    expect(r.purchase.productId, 'a');
  });

  test('receive validates input', () {
    final p = mk('a');
    expect(() => StockService.receive(product: p, qty: 0, purchaseId: 'x'),
        throwsA(isA<StockException>()));
    expect(() => StockService.receive(product: p, qty: -4, purchaseId: 'x'),
        throwsA(isA<StockException>()));
    expect(
        () => StockService.receive(
            product: p, qty: 1, unitCost: -1, purchaseId: 'x'),
        throwsA(isA<StockException>()));
  });

  test('inventory value and low stock', () {
    final items = [mk('a', stock: 2, buy: 5, low: 5), mk('b', stock: 10, buy: 1, low: 5)];
    expect(StockService.inventoryValue(items), 20);
    expect(StockService.lowStock(items).map((p) => p.id), ['a']);
  });
}
