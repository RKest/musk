import 'dart:typed_data';

class Tag {
  static Map<String, String> assocMap = {
    "TIT2": "title",
    "TPE1": "author",
    "TALB": "album",
    "APIC": "picture"
  };

  static Map<String, String> revAssocMap = {
    "title": "TIT2",
    "author": "TPE1",
    "album": "TALB",
    "picture": "APIC"
  };

  Map<String, String> data = {
    "title": "Unknown",
    "author": "Unknown",
    "album": "Unknown"
  };

  late Uint8List? picture;

  Tag.fromBytes(Uint8List bytes){
    assert(bytes.sublist(0, 5) == [0x49, 0x44, 0x33, 3, 0]);
    final int tagSize = ID3.decodeTagSize(bytes.sublist(6, 10));
    // ignore: unused_local_variable
    final int noTrailingBytes = ID3.numberOfTrailingBytes(bytes, tagSize);
    int i = 10;
    while (i < tagSize){
      if (bytes.sublist(i, i + 4).every((el) => el == 0x00)){
        break;
      }
      final String frameCode = String.fromCharCodes(bytes.sublist(i, i + 4));
		  i += 4;

		  final int frameSize = ID3.decodeFrameSize(bytes.sublist(i, i + 4));
		  i += 4;

		  //Ignoring the flags
		  i += 2;

      if(assocMap.containsKey(frameCode)){
        if (frameCode == "picture"){
          picture = bytes.sublist(i, i + frameSize);
        }else{
          final String frameValue = EncodedString.decodeString(bytes.sublist(i, i + frameSize));
          data[assocMap[frameCode]!] = frameValue;
        }
      }
    }
  }

  Tag.fromValues(String? title, String? author, String? album, Uint8List? picture) 
  {
    picture = picture;
    data["title"] = title ?? "Unknown";
    data["author"] = author ?? "Unknown";
    data["album"] = album ?? "Unknown";
  }

  // Uint8List encode(){

  // }

}

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
        ret[2 * i + 1] =
            (bytes[i] / 256).floor() >>> 0; //Header should be "fe ff"
      }
      return ret;
    }
  }

  Uint8List headerBytes() {
    if (isUtf8Encoded) {
      return Uint8List.fromList([0x00]);
    } else {
      return Uint8List.fromList([0x01, 0xfe, 0xff]);
    }
  }

  static String decodeString(Uint8List bytes) {
    if (bytes[0] == 0x00) {
      return String.fromCharCodes(bytes.sublist(1));
    } else if (bytes[0] == 0x01) {
      Uint16List u16Bytes = Uint16List((bytes.length / 2).floor());
      //LittleEndian
      if (bytes[1] == 0xff && bytes[2] == 0xfe) {
        for (int i = 0; i < u16Bytes.length; i++) {
          u16Bytes[i] = (bytes[2 * i + 4] << 8) + bytes[2 * i + 3];
        }
        //BigEndian
      } else if (bytes[1] == 0xfe && bytes[2] == 0xff) {
        for (int i = 0; i < u16Bytes.length; i++) {
          u16Bytes[i] = (bytes[2 * i + 3] << 8) + bytes[2 * i + 4];
        }
      } else {
        throw "Wrongly encoded utf16 string";
      }
      return String.fromCharCodes(u16Bytes);
    } else {
      throw "First byte of a string wrongly encoded";
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

  static int decodeFrameSize(Uint8List bytes) {
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

  static Uint8List encodeFrameSize(int size) {
    Uint8List bytes = Uint8List.fromList([0, 0, 0, 0]);
    bytes[0] = (size & 0xff000000) >> 24;
    bytes[1] = (size & 0x00ff0000) >> 16;
    bytes[2] = (size & 0x0000ff00) >> 8;
    bytes[3] = (size & 0x000000ff);
    return bytes;
  }

  static int numberOfTrailingBytes(Uint8List bytes, int size){
    	int count = 0;
	    final int actualSize = size + 9;
	    for (var i = actualSize - 1; i != 0; i--) {
		    if (bytes[i] == 0x00){
			    count++;
        }
		    else{

			    break;
        }
      }
      return count;
  }

}
