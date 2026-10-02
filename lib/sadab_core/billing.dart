import 'package:flutter/foundation.dart';

import 'models.dart';
import 'parsing.dart';

class EmptyCartException implements Exception {
  const EmptyCartException();
  @override
  String toString() => 'The cart is empty.';
}

class InsufficientStockException implements Exception {
  const InsufficientStockException(this.productName, this.available, this.requested);
  final String productName;
  final int available;
  final int requested;
  @override
  String toString() =>
      'Only $available in stock for "$productName" (requested $requested).';
}

class ProductNotFoundException implements Exception {
  const ProductNotFoundException(this.productName);
  final String productName;
  @override
  String toString() => '"$productName" no longer exists in inventory.';
}

class CartLine {
  CartLine(this.product, this.qty);
  final Product product;
  int qty;
  double get lineTotal => qty * product.sellPrice;
}

class Cart extends ChangeNotifier {
  final Map<String, CartLine> _lines = {};

  List<CartLine> get lines => List.unmodifiable(_lines.values);
  bool get isEmpty => _lines.isEmpty;
  int get itemCount => _lines.values.fold(0, (s, l) => s + l.qty);
  double get total =>
      round2(_lines.values.fold(0.0, (s, l) => s + l.lineTotal));

  int qtyOf(String productId) => _lines[productId]?.qty ?? 0;

  void add(Product p, {int qty = 1}) {
    if (qty <= 0) throw ArgumentError.value(qty, 'qty', 'must be > 0');
    final next = qtyOf(p.id) + qty;
    if (next > p.stock) throw InsufficientStockException(p.name, p.stock, next);
    final line = _lines[p.id];
    if (line == null) {
      _lines[p.id] = CartLine(p, next);
    } else {
      line.qty = next;
    }
    notifyListeners();
  }

  void setQty(String productId, int qty) {
    final line = _lines[productId];
    if (line == null) return;
    if (qty <= 0) {
      _lines.remove(productId);
    } else {
      if (qty > line.product.stock) {
        throw InsufficientStockException(
            line.product.name, line.product.stock, qty);
      }
      line.qty = qty;
    }
    notifyListeners();
  }

  void remove(String productId) {
    if (_lines.remove(productId) != null) notifyListeners();
  }

  void clear() {
    if (_lines.isEmpty) return;
    _lines.clear();
    notifyListeners();
  }
}

class CheckoutResult {
  const CheckoutResult({required this.inventory, required this.sale});
  final List<Product> inventory;
  final Sale sale;
}

class BillingService {
  static CheckoutResult checkout({
    required Cart cart,
    required List<Product> inventory,
    required String saleId,
    DateTime? now,
  }) {
    if (cart.isEmpty) throw const EmptyCartException();
    final byId = {for (final p in inventory) p.id: p};
    final updated = Map<String, Product>.from(byId);
    final items = <SaleItem>[];

    for (final line in cart.lines) {
      final cur = byId[line.product.id];
      if (cur == null) throw ProductNotFoundException(line.product.name);
      if (line.qty > cur.stock) {
        throw InsufficientStockException(cur.name, cur.stock, line.qty);
      }
      updated[cur.id] = cur.copyWith(stock: cur.stock - line.qty);
      items.add(SaleItem(
        productId: cur.id,
        name: cur.name,
        qty: line.qty,
        unitPrice: cur.sellPrice,
      ));
    }

    final total = round2(items.fold(0.0, (s, i) => s + i.lineTotal));
    return CheckoutResult(
      inventory: [for (final p in inventory) updated[p.id]!],
      sale: Sale(
        id: saleId,
        date: now ?? DateTime.now(),
        items: items,
        total: total,
      ),
    );
  }
}
