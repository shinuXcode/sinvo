/// Plain data models with strict JSON validation.
/// Unknown JSON fields are kept in [extra] and written back on export.

String _str(Map<String, dynamic> j, String k,
    {bool required = true, String def = ''}) {
  final v = j[k];
  if (v == null) {
    if (required) throw FormatException('Missing "$k"');
    return def;
  }
  if (v is! String) throw FormatException('"$k" must be text');
  return v;
}

double _money(Map<String, dynamic> j, String k) {
  final v = j[k];
  if (v is! num || !v.isFinite || v < 0) {
    throw FormatException('"$k" must be a non-negative number');
  }
  return v.toDouble();
}

int _int(Map<String, dynamic> j, String k, {int? def, int min = 0}) {
  final v = j[k];
  if (v == null && def != null) return def;
  if (v is num && v.isFinite && v == v.truncateToDouble() && v >= min) {
    return v.toInt();
  }
  throw FormatException('"$k" must be a whole number >= $min');
}

DateTime _date(Map<String, dynamic> j, String k) {
  final v = j[k];
  final d = v is String ? DateTime.tryParse(v) : null;
  if (d == null) throw FormatException('"$k" must be an ISO date');
  return d;
}

Map<String, dynamic> _extra(Map<String, dynamic> j, Set<String> known) => {
      for (final e in j.entries)
        if (!known.contains(e.key)) e.key: e.value,
    };

class Product {
  const Product({
    required this.id,
    required this.name,
    this.sku = '',
    this.category = '',
    required this.buyPrice,
    required this.sellPrice,
    required this.stock,
    this.lowStockThreshold = 5,
    this.extra = const {},
  });

  final String id;
  final String name;
  final String sku;
  final String category;
  final double buyPrice;
  final double sellPrice;
  final int stock;
  final int lowStockThreshold;
  final Map<String, dynamic> extra;

  bool get isLowStock => stock <= lowStockThreshold;
  bool get isOutOfStock => stock <= 0;

  Product copyWith({
    String? name,
    String? sku,
    String? category,
    double? buyPrice,
    double? sellPrice,
    int? stock,
    int? lowStockThreshold,
  }) =>
      Product(
        id: id,
        name: name ?? this.name,
        sku: sku ?? this.sku,
        category: category ?? this.category,
        buyPrice: buyPrice ?? this.buyPrice,
        sellPrice: sellPrice ?? this.sellPrice,
        stock: stock ?? this.stock,
        lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
        extra: extra,
      );

  static const _known = {
    'id', 'name', 'sku', 'category', 'buyPrice', 'sellPrice', 'stock',
    'lowStockThreshold',
  };

  Map<String, dynamic> toJson() => {
        ...extra,
        'id': id,
        'name': name,
        'sku': sku,
        'category': category,
        'buyPrice': buyPrice,
        'sellPrice': sellPrice,
        'stock': stock,
        'lowStockThreshold': lowStockThreshold,
      };

  factory Product.fromJson(Map<String, dynamic> j) {
    final id = _str(j, 'id');
    final name = _str(j, 'name').trim();
    if (id.isEmpty) throw const FormatException('Product id is empty');
    if (name.isEmpty) throw const FormatException('Product name is empty');
    return Product(
      id: id,
      name: name,
      sku: _str(j, 'sku', required: false).trim(),
      category: _str(j, 'category', required: false).trim(),
      buyPrice: _money(j, 'buyPrice'),
      sellPrice: _money(j, 'sellPrice'),
      stock: _int(j, 'stock'),
      lowStockThreshold: _int(j, 'lowStockThreshold', def: 5),
      extra: _extra(j, _known),
    );
  }
}

class SaleItem {
  const SaleItem({
    required this.productId,
    required this.name,
    required this.qty,
    required this.unitPrice,
  });

  final String productId;
  final String name;
  final int qty;
  final double unitPrice;

  double get lineTotal => qty * unitPrice;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'qty': qty,
        'unitPrice': unitPrice,
      };

  factory SaleItem.fromJson(Map<String, dynamic> j) => SaleItem(
        productId: _str(j, 'productId'),
        name: _str(j, 'name'),
        qty: _int(j, 'qty', min: 1),
        unitPrice: _money(j, 'unitPrice'),
      );
}

class Sale {
  const Sale({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    this.extra = const {},
  });

  final String id;
  final DateTime date;
  final List<SaleItem> items;
  final double total;
  final Map<String, dynamic> extra;

  static const _known = {'id', 'date', 'items', 'total'};

  Map<String, dynamic> toJson() => {
        ...extra,
        'id': id,
        'date': date.toUtc().toIso8601String(),
        'items': [for (final i in items) i.toJson()],
        'total': total,
      };

  factory Sale.fromJson(Map<String, dynamic> j) {
    final raw = j['items'];
    if (raw is! List || raw.isEmpty) {
      throw const FormatException('"items" must be a non-empty list');
    }
    final items = <SaleItem>[];
    for (final r in raw) {
      if (r is! Map<String, dynamic>) {
        throw const FormatException('Sale item must be an object');
      }
      items.add(SaleItem.fromJson(r));
    }
    return Sale(
      id: _str(j, 'id'),
      date: _date(j, 'date'),
      items: items,
      total: _money(j, 'total'),
      extra: _extra(j, _known),
    );
  }
}

class Purchase {
  const Purchase({
    required this.id,
    required this.date,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.unitCost,
    this.extra = const {},
  });

  final String id;
  final DateTime date;
  final String productId;
  final String productName;
  final int qty;
  final double unitCost;
  final Map<String, dynamic> extra;

  double get total => qty * unitCost;

  static const _known = {
    'id', 'date', 'productId', 'productName', 'qty', 'unitCost',
  };

  Map<String, dynamic> toJson() => {
        ...extra,
        'id': id,
        'date': date.toUtc().toIso8601String(),
        'productId': productId,
        'productName': productName,
        'qty': qty,
        'unitCost': unitCost,
      };

  factory Purchase.fromJson(Map<String, dynamic> j) => Purchase(
        id: _str(j, 'id'),
        date: _date(j, 'date'),
        productId: _str(j, 'productId'),
        productName: _str(j, 'productName'),
        qty: _int(j, 'qty', min: 1),
        unitCost: _money(j, 'unitCost'),
        extra: _extra(j, _known),
      );
}
