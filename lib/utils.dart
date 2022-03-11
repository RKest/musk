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

  static Future<File> saveToFile(String path, Uint8List data) async {
    final file = await getFile(path);
    return file.writeAsBytes(data, mode: FileMode.append);
  }

  static Future<FileSystemEntity> deleteFile(String path) async {
    final file = await getFile(path);
    return file.delete();
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