import 'dart:typed_data';

class Multipart {
  static const List<int> _filename = [
    102,
    105,
    108,
    101,
    110,
    97,
    109,
    101,
    61,
    34
  ];
  static const int _closing = 34;
  static const int _fnLen = 10;

  static String getFilename(Uint8List list) {
    String ret = "";
    int acc = 0;
    bool recording = false;
    for (int i = 0; i < list.length; i++) {
      if (recording) {
        if (list[i] != _closing) {
          ret += String.fromCharCode(list[i]);
        } else {
          return ret;
        }
      } else if (list[i] == _filename[acc]) {
        acc++;
        if (acc == _fnLen) {
          recording = true;
        }
      } else {
        acc = 0;
      }
    }
    return ret;
  }
}
