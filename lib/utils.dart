import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';

class Utils
{
  static Future<String?> get localIp async {
    final info = NetworkInfo();
    return info.getWifiIP();
  }

  static Future<String> get getFilePath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> getFile(String file) async {
    final path = await getFilePath;
    return File("$path/$file");
  }

  static Future<String> loadAsset(String path) async {
    return await rootBundle.loadString('assets/$path');
  }

  static Future<ByteData> loadAssetBytes(String path) async {
    return rootBundle.load('assets/$path');
  }

  static Future<File> saveToFile(String path, Uint8List data) async {
    final file = await getFile(path);
    return file.writeAsBytes(data, mode: FileMode.append);
  }

  static Future<FileSystemEntity> deleteFile(String path) async {
    final file = await getFile(path);
    return file.delete();
  }

  static Future<List<FileSystemEntity>> scanDir(String path) async {
    final dir = Directory(path);
    return dir.list().toList();
  }

  static void writeAtPostion(String path, Uint8List data, int position) async {
    final File fileForWriting = File(path);
    final RandomAccessFile raf = await file.open(mode: FileMode.append);
    final RandomAccessFile f1 = await raf.setPosition(position);
    await f1.writeFrom(data);
    await f1.close();
  }

  // static Future<String> readFromFile() async {
  //   try {
  //     final file = await getFile;
  //     final String fileContents = await file.readAsString();
  //     return fileContents;
  //   } catch (e) {
  //     return "ERROR: $e";
  //   }
  // }
}

