import 'package:bessie/src/features/rosters/models/natural_compare.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<String> sorted(List<String> values) => [...values]..sort(naturalCompare);

  test('orders digit runs by value', () {
    expect(sorted(['cabin 10', 'cabin 2', 'cabin 1']), ['cabin 1', 'cabin 2', 'cabin 10']);
  });

  test('treats leading zeros as equal in value', () {
    expect(naturalCompare('a007', 'a7'), 0);
    expect(naturalCompare('a08', 'a9'), lessThan(0));
  });

  test('falls back to plain order for text and prefixes', () {
    expect(sorted(['b', 'a', 'ab']), ['a', 'ab', 'b']);
    expect(naturalCompare('abc', 'abc1'), lessThan(0));
    expect(naturalCompare('', 'a'), lessThan(0));
  });

  test('handles numbers longer than an int', () {
    expect(naturalCompare('x99999999999999999999', 'x100000000000000000000'), lessThan(0));
  });
}
