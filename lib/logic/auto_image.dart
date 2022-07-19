import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'algs.dart';
import 'id3.dart';
import 'package:http/http.dart' as http;

//https://serpapi.com/search.json?q=Apple&tbm=isch&ijn=0&api_key=1a169cc8bfc08e7b3bec08e0d7ca2ce9ea02d36620f3643aec79271da0d76884

const baseHost = "serpapi.com";
const baseScheme = "https";
const basePath = "/search.json/";

class AutoImage {
  final String _terms;
  AutoImage(Tag tag)
      : _terms = Checker<String>.thatThrows(
                "No information to find image automatically")
            .check(tag.album.isNotEmpty, "${tag.album} Cover Art")
            .check(tag.artist.isNotEmpty && tag.title.isNotEmpty,
                "${tag.artist} - ${tag.title} Album Cover Art")
            .value;

  Future<List<String>> getImages() async {
    final apikey = await rootBundle.loadString('assets/apikey.txt');
    final uri = _query(apikey);
    final res = await http.get(uri);
    // Local testing
    // final json = await rootBundle.loadString('assets/test.json');
    final json = res.body;
    final parsedRes = ImageRes.fromJson(json).values; //res.body
    final filteredImageUrls = parsedRes
        .map((img) => img.url)
        .where(doesntEndWith('svg'))
        .toList()
        .sublist(0, min(parsedRes.length, 3));
    return filteredImageUrls;
  }

  Uri _query(String apiKey) {
    return Uri(
      scheme: baseScheme,
      host: baseHost,
      path: basePath,
      queryParameters: {
        "q": _terms,
        "tbm": 'isch',
        "ijn": '0',
        "api_key": apiKey
      },
    );
  }
}

class ImageRes {
  final List<ImageInstance> values;
  ImageRes(this.values);
  factory ImageRes.fromJson(String sjson) {
    final json = jsonDecode(sjson);
    final List<dynamic> jsonValues = json['images_results'];
    final values = jsonValues.map(ImageInstance.fromJson).toList();
    return ImageRes(values);
  }
}

class ImageInstance {
  final String url;
  ImageInstance(this.url);
  factory ImageInstance.fromJson(dynamic json) {
    final url = json['original'];
    return ImageInstance(url);
  }
}
