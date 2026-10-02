import 'package:flutter_test/flutter_test.dart';
import 'package:sadab_invo/sadab_core/billing.dart';

import 'helpers.dart';

void main() {
  test('cart total and quantity limits', () {
    final p = mk('a', sell: 10.5, stock: 5);
    final cart = Cart()..add(p, qty: 2);
    expect(cart.total, 21);
    expect(() => cart.add(p, qty: 4), throwsA(isA<InsufficientStockException>()));
    expect(cart.qtyOf('a'), 2);
    expect(() => cart.setQty('a', 6), throwsA(isA<InsufficientStockException>()));
    cart.setQty('a', 0);
    expect(cart.isEmpty, isTrue);
  });

  test('checkout deducts stock and builds sale', () {
    final a = mk('a', sell: 10.5, stock: 5);
    final b = mk('b', sell: 2, stock: 3);
    final cart = Cart()
      ..add(a, qty: 2)
      ..add(b);
    final r = BillingService.checkout(
      cart: cart,
      inventory: [a, b],
      saleId: 's1',
      now: DateTime.utc(2026, 1, 1),
    );
    expect(r.inventory.firstWhere((p) => p.id == 'a').stock, 3);
    expect(r.inventory.firstWhere((p) => p.id == 'b').stock, 2);
    expect(r.sale.total, 23);
    expect(r.sale.items.length, 2);
    expect(a.stock, 5);
  });

  test('checkout rejects empty cart', () {
    expect(
      () => BillingService.checkout(cart: Cart(), inventory: [], saleId: 's'),
      throwsA(isA<EmptyCartException>()),
    );
  });

  test('checkout re-checks stock against current inventory', () {
    final a = mk('a', stock: 5);
    final cart = Cart()..add(a, qty: 4);
    final sold = a.copyWith(stock: 2);
    expect(
      () => BillingService.checkout(cart: cart, inventory: [sold], saleId: 's'),
      throwsA(isA<InsufficientStockException>()),
    );
  });

  test('checkout rejects deleted products', () {
    final cart = Cart()..add(mk('a'));
    expect(
      () => BillingService.checkout(cart: cart, inventory: [], saleId: 's'),
      throwsA(isA<ProductNotFoundException>()),
    );
  });
}
