import 'dart:convert';

import 'models.dart';

class BackupException implements Exception {
  const BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

class BackupData {
  const BackupData({
    required this.products,
    required this.sales,
    required this.purchases,
    required this.settings,
    this.extra = const {},
  });

  final List<Product> products;
  final List<Sale> sales;
  final List<Purchase> purchases;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> extra;
}

abstract class BackupStore {
  Future<BackupData> snapshot();
  Future<void> replaceAll(BackupData data);
}

class RestoreResult {
  const RestoreResult({
    required this.products,
    required this.sales,
    required this.purchases,
  });
  final int products;
  final int sales;
  final int purchases;
}

class BackupService {
  static const appName = 'Sadab Invo';
  static const schemaVersion = 2;

  static String encode(BackupData d, {DateTime? now}) {
    final map = <String, dynamic>{
      ...d.extra,
      'schemaVersion': schemaVersion,
      'app': appName,
      'exportedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'products': [for (final p in d.products) p.toJson()],
      'sales': [for (final s in d.sales) s.toJson()],
      'purchases': [for (final p in d.purchases) p.toJson()],
      'settings': d.settings,
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  static BackupData decode(String raw) {
    final Object? parsed;
    try {
      parsed = jsonDecode(raw);
    } on FormatException {
      throw const BackupException('This file is not valid JSON.');
    }
    if (parsed is! Map<String, dynamic>) {
      throw const BackupException('Backup must be a JSON object.');
    }
    if (parsed['app'] != appName) {
      throw const BackupException('This is not a Sadab Invo backup.');
    }
    final v = parsed['schemaVersion'];
    if (v is! int || v < 1) {
      throw const BackupException('Missing or invalid schemaVersion.');
    }
    if (v > schemaVersion) {
      throw BackupException(
          'Backup is from a newer app version (schema $v). Update the app first.');
    }

    final products = _list(parsed, 'products', Product.fromJson, required: true);
    final sales = _list(parsed, 'sales', Sale.fromJson, required: true);
    final purchases =
        _list(parsed, 'purchases', Purchase.fromJson, required: v >= 2);

    final ids = <String>{};
    for (final p in products) {
      if (!ids.add(p.id)) {
        throw BackupException('Duplicate product id "${p.id}".');
      }
    }

    final s = parsed['settings'];
    if (s != null && s is! Map<String, dynamic>) {
      throw const BackupException('"settings" must be an object.');
    }
    if (s == null && v >= 2) {
      throw const BackupException('Missing "settings".');
    }

    const known = {
      'schemaVersion', 'app', 'exportedAt', 'products', 'sales', 'purchases',
      'settings',
    };
    return BackupData(
      products: products,
      sales: sales,
      purchases: purchases,
      settings: (s as Map<String, dynamic>?) ?? const {},
      extra: {
        for (final e in parsed.entries)
          if (!known.contains(e.key)) e.key: e.value,
      },
    );
  }

  static Future<RestoreResult> restore(String raw, BackupStore store) async {
    final data = decode(raw);
    final snap = await store.snapshot();
    try {
      await store.replaceAll(data);
    } catch (e) {
      try {
        await store.replaceAll(snap);
      } catch (_) {}
      throw BackupException('Restore failed; existing data was kept. ($e)');
    }
    return RestoreResult(
      products: data.products.length,
      sales: data.sales.length,
      purchases: data.purchases.length,
    );
  }

  static List<T> _list<T>(
    Map<String, dynamic> root,
    String key,
    T Function(Map<String, dynamic>) parse, {
    required bool required,
  }) {
    final raw = root[key];
    if (raw == null) {
      if (required) throw BackupException('Missing "$key".');
      return const [];
    }
    if (raw is! List) throw BackupException('"$key" must be a list.');
    final out = <T>[];
    for (var i = 0; i < raw.length; i++) {
      final r = raw[i];
      if (r is! Map<String, dynamic>) {
        throw BackupException('$key[$i] must be an object.');
      }
      try {
        out.add(parse(r));
      } on FormatException catch (e) {
        throw BackupException('$key[$i]: ${e.message}');
      }
    }
    return out;
  }
}
