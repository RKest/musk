import 'dart:math';


void shuffleExceptPos(List elements, int exceptPos, [int start = 0, int? end, Random? random]) {
  random ??= Random();
  end ??= elements.length;
  var length = end - start;
  while (length > 1) {
    var pos = random.nextInt(length);
    length--;
    if (exceptPos != start + pos && exceptPos != start + length){
      swap(elements, start + pos, start + length);
    }
  }
}

void swap(List elements, int inx1, int inx2){
  final temp = elements[inx1];
  elements[inx1] = elements[inx2];
  elements[inx2] = temp;
}