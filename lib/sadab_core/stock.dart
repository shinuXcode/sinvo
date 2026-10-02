import 'models.dart';

class StockException implements Exception {
  const StockException(this.message);
  final String message;
  @override
  String toString() => message;
}

class StockReceipt {
  const StockReceipt({required this.product, required this.purchase});
  final Product product;
  final Purchase purchase;
}

class StockService {
  static StockReceipt receive({
    required Product product,
    required int qty,
    double? unitCost,
    required String purchaseId,
    DateTime? now,
  }) {
    if (qty <= 0) throw const StockException('Quantity must be at least 1.');
    final cost = unitCost ?? product.buyPrice;
    if (!cost.isFinite || cost < 0) {
      throw const StockException('Unit cost must be zero or more.');
    }
    return StockReceipt(
      product: product.copyWith(stock: product.stock + qty, buyPrice: cost),
      purchase: Purchase(
        id: purchaseId,
        date: now ?? DateTime.now(),
        productId: product.id,
        productName: product.name,
        qty: qty,
        unitCost: cost,
      ),
    );
  }

  static double inventoryValue(Iterable<Product> products) =>
      products.fold(0.0, (s, p) => s + p.stock * p.buyPrice);

  static List<Product> lowStock(Iterable<Product> products) =>
      [for (final p in products) if (p.isLowStock) p];
}
