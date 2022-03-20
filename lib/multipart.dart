import 'dart:typed_data';

class Multipart {
  static const List<int> _filename = [
    102, 105, 108, 101, 110, 97, 109, 101, 61, 34 // prevent dartfmt
  ];

  static const List<int> _id3 = [
    0x49, 0x44, 0x33 // prevent dartfmt
  ];
  static const int _closing = 34;

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
        if (acc == _filename.length) {
          recording = true;
        }
      } else {
        acc = 0;
      }
    }
    return ret;
  }

  static int mp3DataStartIndex(Uint8List bytes) {
    int currLen = 0;
    int i = 0;
    for (i = 0; i < 1000; i++) {
      if (bytes[i] == _id3[currLen]) {
        currLen += 1;
        if (currLen == 3) {
          break;
        }
      } else {
        currLen = 0;
      }
    }

    return i - 2;
  }
}
