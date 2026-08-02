import 'package:flutter_test/flutter_test.dart';
import 'package:budget_app/format.dart';

void main() {
  test('krw formats with commas and sign', () {
    expect(krw(1234567), '₩1,234,567');
    expect(krw(-5000), '-₩5,000');
    expect(krw(0), '₩0');
  });

  test('signed prefixes by type', () {
    expect(signed('income', 1000), '+₩1,000');
    expect(signed('expense', 1000), '-₩1,000');
  });
}
