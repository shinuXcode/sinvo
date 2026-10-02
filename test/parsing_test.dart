import 'package:flutter_test/flutter_test.dart';
import 'package:sadab_invo/sadab_core/parsing.dart';

void main() {
  test('parseMoney accepts valid values', () {
    expect(parseMoney('1,250.50'), 1250.5);
    expect(parseMoney(' 0 '), 0);
  });

  test('parseMoney rejects bad values', () {
    for (final s in [null, '', '  ', 'abc', '-1', 'NaN', 'Infinity']) {
      expect(parseMoney(s), isNull, reason: '$s');
    }
  });

  test('parseQuantity', () {
    expect(parseQuantity('12'), 12);
    expect(parseQuantity('1.5'), isNull);
    expect(parseQuantity('-3'), isNull);
    expect(parseQuantity(''), isNull);
  });

  test('round2 avoids float drift', () {
    expect(round2(0.1 + 0.2), 0.3);
  });
}
