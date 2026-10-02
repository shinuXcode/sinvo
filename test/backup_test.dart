import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sadab_invo/sadab_core/backup.dart';
import 'package:sadab_invo/sadab_core/models.dart';

import 'helpers.dart';

class MemStore implements BackupStore {
  MemStore(this.data, {this.failFirstWrite = false});
  BackupData data;
  bool failFirstWrite;
  int writes = 0;

  @override
  Future<BackupData> snapshot() async => data;

  @override
  Future<void> replaceAll(BackupData d) async {
    writes++;
    if (failFirstWrite && writes == 1) throw StateError('disk full');
    data = d;
  }
}

BackupData sample() => BackupData(
      products: [mk('a', name: 'Pen')],
      sales: [
        Sale(
          id: 's1',
          date: DateTime.utc(2026, 1, 1),
          items: const [SaleItem(productId: 'a', name: 'Pen', qty: 1, unitPrice: 10)],
          total: 10,
        ),
      ],
      purchases: [
        Purchase(
          id: 'p1',
          date: DateTime.utc(2026, 1, 1),
          productId: 'a',
          productName: 'Pen',
          qty: 5,
          unitCost: 4,
        ),
      ],
      settings: const {'shopName': 'Sadab'},
    );

Map<String, dynamic> asMap(BackupData d) =>
    jsonDecode(BackupService.encode(d)) as Map<String, dynamic>;

void main() {
  test('encode produces versioned structure', () {
    final m = asMap(sample());
    expect(m['schemaVersion'], 2);
    expect(m['app'], 'Sadab Invo');
    expect(m['exportedAt'], isA<String>());
    expect((m['products'] as List).length, 1);
  });

  test('round trip', () {
    final back = BackupService.decode(BackupService.encode(sample()));
    expect(back.products.single.name, 'Pen');
    expect(back.sales.single.total, 10);
    expect(back.purchases.single.qty, 5);
    expect(back.settings['shopName'], 'Sadab');
  });

  test('unknown fields are preserved', () {
    final m = asMap(sample())
      ..['futureTopLevel'] = {'x': 1}
      ..['products'] = [
        {...((asMap(sample())['products'] as List).first as Map<String, dynamic>), 'tag': 'z'},
      ];
    final back = BackupService.decode(jsonEncode(m));
    final again = asMap(back);
    expect(again['futureTopLevel'], {'x': 1});
    expect((again['products'] as List).first['tag'], 'z');
  });

  group('validation rejects', () {
    void bad(String why, Map<String, dynamic> Function(Map<String, dynamic>) f) {
      test(why, () {
        final m = f(asMap(sample()));
        expect(() => BackupService.decode(jsonEncode(m)),
            throwsA(isA<BackupException>()));
      });
    }

    bad('wrong app', (m) => m..['app'] = 'Other');
    bad('missing schemaVersion', (m) => m..remove('schemaVersion'));
    bad('newer schema', (m) => m..['schemaVersion'] = 99);
    bad('missing products', (m) => m..remove('products'));
    bad('products not a list', (m) => m..['products'] = {});
    bad('negative price', (m) {
      ((m['products'] as List).first as Map<String, dynamic>)['sellPrice'] = -1;
      return m;
    });
    bad('non-object record', (m) => m..['sales'] = [42]);
    bad('duplicate product ids', (m) {
      final first = (m['products'] as List).first;
      m['products'] = [first, first];
      return m;
    });
    bad('missing settings (v2)', (m) => m..remove('settings'));
  });

  test('corrupted / non-object JSON gives BackupException', () {
    expect(() => BackupService.decode('{not json'), throwsA(isA<BackupException>()));
    expect(() => BackupService.decode('[]'), throwsA(isA<BackupException>()));
    expect(() => BackupService.decode(''), throwsA(isA<BackupException>()));
  });

  test('restore replaces data after validation', () async {
    final store = MemStore(const BackupData(
        products: [], sales: [], purchases: [], settings: {}));
    final r = await BackupService.restore(BackupService.encode(sample()), store);
    expect(r.products, 1);
    expect(store.data.products.length, 1);
  });

  test('invalid backup never touches the store', () async {
    final original = sample();
    final store = MemStore(original);
    await expectLater(
        BackupService.restore('{"app":"Sadab Invo"}', store),
        throwsA(isA<BackupException>()));
    expect(store.writes, 0);
    expect(identical(store.data, original), isTrue);
  });

  test('failed write rolls back to snapshot', () async {
    final original = sample();
    final store = MemStore(original, failFirstWrite: true);
    final incoming = BackupData(
        products: [mk('z')], sales: const [], purchases: const [], settings: const {});
    await expectLater(
        BackupService.restore(BackupService.encode(incoming), store),
        throwsA(isA<BackupException>()));
    expect(store.data.products.single.id, 'a');
  });
}
