import 'dart:async';

import 'package:flutter/foundation.dart';

import 'models.dart';

/// Debounced, cached product search.
///
/// Filtering runs only when the query / filters / product list change,
/// never inside build(). Use one instance for Products and one for Billing.
/// Matches name, SKU and category; every space-separated word must match.
class ProductSearchController extends ChangeNotifier {
  ProductSearchController({this.debounce = const Duration(milliseconds: 200)});

  final Duration debounce;

  List<Product> _all = const [];
  List<String> _haystack = const [];
  List<Product> _results = const [];
  List<String> _categories = const [];
  String _query = '';
  String? _category;
  bool _lowOnly = false;
  Timer? _timer;

  List<Product> get results => _results;
  List<String> get categories => _categories;
  String? get category => _category;
  bool get lowStockOnly => _lowOnly;
  String get query => _query;

  void setProducts(List<Product> products) {
    _all = products;
    _haystack = [
      for (final p in products)
        '${p.name} ${p.sku} ${p.category}'.toLowerCase(),
    ];
    _categories = (<String>{
      for (final p in products)
        if (p.category.isNotEmpty) p.category,
    }.toList()
      ..sort());
    if (_category != null && !_categories.contains(_category)) {
      _category = null;
    }
    _apply();
  }

  void setQuery(String raw) {
    final q = raw.trim().toLowerCase();
    _timer?.cancel();
    if (q == _query) return;
    if (debounce == Duration.zero) {
      _query = q;
      _apply();
      return;
    }
    _timer = Timer(debounce, () {
      _query = q;
      _apply();
    });
  }

  void setCategory(String? category) {
    _category = category;
    _apply();
  }

  void setLowStockOnly(bool value) {
    _lowOnly = value;
    _apply();
  }

  void _apply() {
    final tokens = _query.isEmpty ? const <String>[] : _query.split(RegExp(r'\s+'));
    final out = <Product>[];
    for (var i = 0; i < _all.length; i++) {
      final p = _all[i];
      if (_category != null && p.category != _category) continue;
      if (_lowOnly && !p.isLowStock) continue;
      var ok = true;
      for (final t in tokens) {
        if (!_haystack[i].contains(t)) {
          ok = false;
          break;
        }
      }
      if (ok) out.add(p);
    }
    _results = out;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
