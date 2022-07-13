import 'dart:math';

void shuffleExceptPos(List elements, int exceptPos,
    [int start = 0, int? end, Random? random]) {
  random ??= Random();
  end ??= elements.length;
  var length = end - start;
  while (length > 1) {
    var pos = random.nextInt(length);
    length--;
    if (exceptPos != start + pos && exceptPos != start + length) {
      swap(elements, start + pos, start + length);
    }
  }
}

void swap(List elements, int inx1, int inx2) {
  final temp = elements[inx1];
  elements[inx1] = elements[inx2];
  elements[inx2] = temp;
}

class Checker<T> {
  final bool _doesThrow;
  final String? _err;
  final T? _defaultVal;

  Checker.thatThrows(this._err)
      : _doesThrow = true,
        _defaultVal = null;
  Checker.withDefaultVal(this._defaultVal)
      : _doesThrow = false,
        _err = null;

  T? _finalVal;
  Checker check(bool condition, T valueIf) {
    if (condition) {
      _finalVal = valueIf;
    }
    return this;
  }

  T get value {
    if (_finalVal != null) {
      return _finalVal!;
    } else if (_doesThrow) {
      throw Exception(_err);
    } else {
      return _defaultVal!;
    }
  }
}
