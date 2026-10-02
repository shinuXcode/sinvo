double? parseMoney(Object? raw) {
  if (raw is num) {
    if (raw.isFinite && raw >= 0) return round2(raw.toDouble());
    return null;
  }
  if (raw is! String) return null;
  final s = raw.trim().replaceAll(',', '');
  if (s.isEmpty) return null;
  final v = double.tryParse(s);
  if (v == null || !v.isFinite || v < 0) return null;
  return round2(v);
}

int? parseQuantity(Object? raw) {
  if (raw is int) return raw > 0 ? raw : null;
  if (raw is num) return raw.isFinite && raw == raw.truncateToDouble() && raw > 0
      ? raw.toInt()
      : null;
  if (raw is! String) return null;
  final s = raw.trim();
  final v = int.tryParse(s);
  return v != null && v > 0 ? v : null;
}

double round2(double value) =>
    (value * 100).roundToDouble() / 100;
