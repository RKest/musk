import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' show get, Response;
import 'dart:convert' show utf8;

class Tag {
  static const Map<String, String> _assocMap = {
    "TIT2": "title",
    "TPE1": "author",
    "TALB": "album",
    "APIC": "picture"
  };

  static const Map<String, String> _revAssocMap = {
    "title": "TIT2",
    "author": "TPE1",
    "album": "TALB",
    "picture": "APIC"
  };

  final Map<String, String> _data = {
    "title": "Unknown",
    "author": "Unknown",
    "album": "Unknown"
  };

  set title(String newVal) {
    _data["title"] = newVal;
  }

  set artist(String newVal) {
    _data["author"] = newVal;
  }

  set album(String newVal) {
    _data["album"] = newVal;
  }

  setPictureFromFile(XFile pictureFile) async {
    final String mime =
        pictureFile.mimeType ?? "image/${pictureFile.name.split('.').last}";
    final Uint8List pictureBinData = await pictureFile.readAsBytes();
    _setPictureBytes(mime, pictureBinData);
  }

  setPictureFromUri(String uri) async {
    final Response res = await get(Uri.parse(uri));
    final Uint8List pictureBinData = res.bodyBytes;
    final String ext = uri.split('.').last;
    final String mime = "image/$ext";
    _setPictureBytes(mime, pictureBinData);
  }

  _setPictureBytes(String mime, Uint8List pictureBinData) {
    final EncodedString encodedMimetype = EncodedString(mime);
    final Uint8List bytes = Uint8List.fromList([
      ...encodedMimetype.headerBytes(),
      ...encodedMimetype.writeableBytes(),
      ...encodedMimetype.nullTerminator(),
      0x03, // <-- picture type of "Front Cover",
      0x00, // <-- description which is empty
      ...pictureBinData
    ]);
    picture = bytes;
  }

  String get title {
    return _data["title"]!;
  }

  String get artist {
    return _data["author"]!;
  }

  String get album {
    return _data["album"]!;
  }

  int _imageCutoffPoint = 0;

  Image get getImage {
    if (picture != null && picture!.isNotEmpty) {
      return Image.memory(picture!.sublist(_imageCutoffPoint));
    } else {
      return Image.asset("assets/def.png");
    }
  }

  Uint8List? picture;
  String mp3Path;

  Tag.fromBytes(Uint8List bytes, this.mp3Path) {
    if (listEquals(bytes.sublist(0, 3), [73, 68, 51])) {
      final int tagSize = ID3.decodeTagSize(bytes.sublist(6, 10));
      // ignore: unused_local_variable
      // final int noTrailingBytes = ID3.numberOfTrailingBytes(bytes, tagSize);
      int i = 10;
      while (i <= tagSize) {
        if (bytes.sublist(i, i + 4).every((el) => el == 0x00)) {
          break;
        }
        final String frameCode = String.fromCharCodes(bytes.sublist(i, i + 4));
        i += 4;

        final int frameSize = ID3.decodeFrameSize(bytes.sublist(i, i + 4));
        i += 4;

        //Ignoring the flags
        i += 2;

        if (_assocMap.containsKey(frameCode)) {
          if (frameCode == "APIC") {
            final int imageSliceOffPoint =
                ID3.getImageDataSliceOffPoint(bytes.sublist(i, i + frameSize));
            _imageCutoffPoint = imageSliceOffPoint;
            picture = bytes.sublist(i, i + frameSize);
          } else {
            final String frameValue =
                EncodedString.decodeString(bytes.sublist(i, i + frameSize));
            _data[_assocMap[frameCode]!] = frameValue;
          }
        }
        i += frameSize;
      }
    }
  }

  Tag.fromValues(this.mp3Path,
      [String? title, String? author, String? album, Uint8List? picture]) {
    picture = picture;
    _data["title"] = title ?? "Unknown";
    _data["author"] = author ?? "Unknown";
    _data["album"] = album ?? "Unknown";
  }

  Uint8List encode() {
    //I, D, 3, ver 3, rev 0, flags [zeroed], size [four ones for now]
    Uint8List encodedTag =
        Uint8List.fromList([0x49, 0x44, 0x33, 3, 0, 0, 1, 1, 1, 1]);

    _data.forEach((key, val) {
      if (val != "Unknown") {
        final EncodedString encodedFrameCode =
            EncodedString(_revAssocMap[key]!);
        final EncodedString encodedFrameVal = EncodedString(val);
        final Uint8List frameCodeBytes = encodedFrameCode.writeableBytes();
        final Uint8List frameSizeBytes =
            ID3.encodeFrameSize(encodedFrameVal.frameSize());
        final Uint8List frameFlags = Uint8List.fromList([0x00, 0x00]);
        final Uint8List frameValueEncoding = encodedFrameVal.headerBytes();
        final Uint8List frameValueBytes = encodedFrameVal.writeableBytes();

        encodedTag = Uint8List.fromList([
          ...encodedTag,
          ...frameCodeBytes,
          ...frameSizeBytes,
          ...frameFlags,
          ...frameValueEncoding,
          ...frameValueBytes
        ]);
      }
    });

    if (picture != null) {
      final EncodedString encodedFrameCode = EncodedString('APIC');
      final Uint8List frameCodeBytes = encodedFrameCode.writeableBytes();
      final Uint8List frameSizeBytes = ID3.encodeFrameSize(picture!.length);
      final Uint8List frameFlags = Uint8List.fromList([0x00, 0x00]);

      encodedTag = Uint8List.fromList([
        ...encodedTag,
        ...frameCodeBytes,
        ...frameSizeBytes,
        ...frameFlags,
        ...picture!,
      ]);
    }

    final int tagSize = encodedTag.length - 10;
    final Uint8List encodedTagSize = ID3.encodeTagSize(tagSize);
    for (int i = 0; i < 4; i++) {
      encodedTag[i + 6] = encodedTagSize[i];
    }

    return encodedTag;
  }

  static Future<void> updateWithNewValues(Tag oldTag, Tag newTag) async {
    final String pathToChange = oldTag.mp3Path;
    final Uint8List oldTagBytes = await File(pathToChange).readAsBytes();
    final int oldTagSize = ID3.decodeTagSize(oldTagBytes.sublist(6, 10)) +
        10; // + 10 for the 10 bytes before actual tag data
    final Uint8List newEncodedTag = newTag.encode();
    final File newFile = File(pathToChange);
    await newFile.writeAsBytes(newEncodedTag, mode: FileMode.write);
    await newFile.writeAsBytes(oldTagBytes.sublist(oldTagSize),
        mode: FileMode.append);
  }
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

  Uint8List nullTerminator() {
    if (isUtf8Encoded) {
      return Uint8List.fromList([0x00]);
    } else {
      return Uint8List.fromList([0x00, 0x00]);
    }
  }

  int frameSize() {
    if (isUtf8Encoded) {
      return bytes.length + 1;
    } else {
      return bytes.length + 3;
    }
  }

  static String decodeString(Uint8List bytes) {
    //This should handle both ASCII as well as UTF-8, should, if not 0x03 means the string is utf8 encoded
    if (bytes[0] == 0x00) {
      return String.fromCharCodes(bytes.sublist(1));
    } else if (bytes[0] == 0x01) {
      Uint16List u16Bytes = Uint16List((bytes.length / 2).floor());
      //LittleEndian
      if (bytes[1] == 0xff && bytes[2] == 0xfe) {
        for (int i = 0; i < u16Bytes.length; i++) {
          u16Bytes[i] = (bytes[2 * i + 2] << 8) + bytes[2 * i + 1];
        }
        //BigEndian
      } else if (bytes[1] == 0xfe && bytes[2] == 0xff) {
        for (int i = 0; i < u16Bytes.length; i++) {
          u16Bytes[i] = (bytes[2 * i + 1] << 8) + bytes[2 * i + 2];
        }
      } else {
        throw "Wrongly encoded utf16 string";
      }
      return String.fromCharCodes(u16Bytes);
    } else if (bytes[0] == 0x03) {
      return utf8.decode(bytes.sublist(1));
    } else {
      throw "First byte of a string wrongly encoded bytes are $bytes";
    }
  }
}

class ID3 {
  static int decodeTagSize(Uint8List bytes) {
    assert(bytes.length == 4);
    int acc = 0;

    for (int i = 0; i < 4; i++) {
      acc += bytes[3 - i] << (7 * i);
    }
    return acc;
  }

  static int decodeFrameSize(Uint8List bytes) {
    assert(bytes.length == 4);
    int acc = 0;

    for (int i = 0; i < 4; i++) {
      acc += bytes[3 - i] << (8 * i);
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

  static int getImageDataSliceOffPoint(Uint8List bytes) {
    int textEncoding = bytes[0];
    int i = 1;
    while (bytes[i] != 0) {
      i += 1;
    }
    //Ignoring Picture Type
    i += 1;
    if (textEncoding == 0) {
      while (bytes[i] != 0) {
        i += 1;
      }
    } else {
      while (bytes[i] != 0 || bytes[i + 1] != 0) {
        i += 2;
      }
    }
    return i + 1;
  }
}
