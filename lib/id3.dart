import 'dart:typed_data';

class EncodedString {
  bool isUtf8Encoded = true;
  Uint16List bytes;

  EncodedString(String str) : bytes = Uint16List(str.length) {
    for (int i = 0; i < str.length; i++) {
      final int codeUnit = str.codeUnitAt(i);
      if (codeUnit > 127) {
        isUtf8Encoded = false;
      }
      bytes[i] = codeUnit;
    }
  }

  Uint8List writeableBytes() {
    if (isUtf8Encoded) {
      return Uint8List.fromList(bytes.toList());
    } else {
      Uint8List ret = Uint8List(bytes.length * 2);

      for (int i = 0; i < bytes.length; i++) {
        ret[2 * i] = bytes[i] & 0xff;
        ret[2 * i + 1] = (bytes[i] / 256).floor() >>> 0; //Header should be "fe ff"
      }
      return ret;
    }
  }
}

class ID3 {
  static int decodeTagSize(Uint8List bytes) {
    assert(bytes.length == 4);
    int acc = 0;

    for (int i = 0; i < 4; i++) {
      acc += bytes[3 - i] >> (7 * i);
    }
    return acc;
  }

  static int decodeFramSize(Uint8List bytes) {
    assert(bytes.length == 4);
    int acc = 0;

    for (int i = 0; i < 4; i++) {
      acc += bytes[3 - i] >> (8 * i);
    }

    return acc;
  }

  static Uint8List encodeTagSize(int size) {
    Uint8List bytes = Uint8List.fromList([0, 0, 0, 0]);
    bytes[0] = (size & 0xfe00000) >> 21;
    bytes[1] = (size & 0x1fc000) >> 14;
    bytes[2] = (size & 0x3f80) >> 7;
    bytes[3] = (size & 0x7f);
    return bytes;
  }

  static Uint8List encodeframeSize(int size) {
    Uint8List bytes = Uint8List.fromList([0, 0, 0, 0]);
    bytes[0] = (size & 0xff000000) >> 24;
    bytes[1] = (size & 0x00ff0000) >> 16;
    bytes[2] = (size & 0x0000ff00) >> 8;
    bytes[3] = (size & 0x000000ff);
    return bytes;
  }
}
