import 'package:flutter_test/flutter_test.dart';
import 'package:sadab_invo/sadab_core/search.dart';

import 'helpers.dart';

void main() {
  late ProductSearchController c;

  setUp(() {
    c = ProductSearchController(debounce: Duration.zero)
      ..setProducts([
        mk('1', name: 'Blue Pen', sku: 'PN-01', category: 'Stationery', stock: 2),
        mk('2', name: 'Notebook', sku: 'NB-77', category: 'Stationery', stock: 50),
        mk('3', name: 'Cable', sku: 'CB-10', category: 'Electronics', stock: 1),
      ]);
  });

  tearDown(() => c.dispose());

  test('matches name, sku and category', () {
    c.setQuery('pen');
    expect(c.results.map((p) => p.id), ['1']);
    c.setQuery('nb-77');
    expect(c.results.map((p) => p.id), ['2']);
    c.setQuery('electro');
    expect(c.results.map((p) => p.id), ['3']);
  });

  test('multi-word query requires all words', () {
    c.setQuery('blue stationery');
    expect(c.results.map((p) => p.id), ['1']);
    c.setQuery('blue electronics');
    expect(c.results, isEmpty);
  });

  test('category and low-stock filters combine', () {
    c.setCategory('Stationery');
    expect(c.results.length, 2);
    c.setLowStockOnly(true);
    expect(c.results.map((p) => p.id), ['1']);
    expect(c.categories, ['Electronics', 'Stationery']);
  });

  test('debounce delays filtering', () async {
    final d = ProductSearchController(debounce: const Duration(milliseconds: 20))
      ..setProducts([mk('1', name: 'Alpha'), mk('2', name: 'Beta')]);
    d.setQuery('alp');
    expect(d.results.length, 2);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(d.results.map((p) => p.id), ['1']);
    d.dispose();
  });
}
