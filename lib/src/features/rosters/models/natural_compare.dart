/// Compares strings so that runs of digits are ordered by value: "Cabin 2"
/// sorts before "Cabin 10". Callers lowercase the strings first if they want a
/// case-insensitive order.
int naturalCompare(String a, String b) {
  var i = 0;
  var j = 0;
  while (i < a.length && j < b.length) {
    final ca = a.codeUnitAt(i);
    final cb = b.codeUnitAt(j);
    if (_isDigit(ca) && _isDigit(cb)) {
      final endA = _endOfDigits(a, i);
      final endB = _endOfDigits(b, j);
      final numberA = _stripLeadingZeros(a.substring(i, endA));
      final numberB = _stripLeadingZeros(b.substring(j, endB));
      if (numberA.length != numberB.length) return numberA.length.compareTo(numberB.length);
      final byValue = numberA.compareTo(numberB);
      if (byValue != 0) return byValue;
      i = endA;
      j = endB;
    } else {
      if (ca != cb) return ca.compareTo(cb);
      i++;
      j++;
    }
  }
  return (a.length - i).compareTo(b.length - j);
}

bool _isDigit(int codeUnit) => codeUnit >= 0x30 && codeUnit <= 0x39;

int _endOfDigits(String text, int start) {
  var end = start;
  while (end < text.length && _isDigit(text.codeUnitAt(end))) {
    end++;
  }
  return end;
}

String _stripLeadingZeros(String digits) {
  var start = 0;
  while (start < digits.length - 1 && digits.codeUnitAt(start) == 0x30) {
    start++;
  }
  return digits.substring(start);
}
