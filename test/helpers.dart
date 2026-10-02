import 'package:sadab_invo/sadab_core/models.dart';

Product mk(
  String id, {
  String name = 'Item',
  String sku = '',
  String category = '',
  double buy = 5,
  double sell = 10,
  int stock = 10,
  int low = 5,
}) =>
    Product(
      id: id,
      name: name,
      sku: sku,
      category: category,
      buyPrice: buy,
      sellPrice: sell,
      stock: stock,
      lowStockThreshold: low,
    );
