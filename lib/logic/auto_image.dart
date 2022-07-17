import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'algs.dart';
import 'id3.dart';
import 'package:http/http.dart' as http;

const baseHost = "contextualwebsearch-websearch-v1.p.rapidapi.com";
const baseScheme = "https";
const basePath = "/api/Search/ImageSearchAPI/";

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
    final uri = _query();
    final apikey = await rootBundle.loadString('assets/apikey.txt');
    final res = await http.get(uri, headers: {
      'X-RapidAPI-Key': apikey,
      'X-RapidAPI-Host': 'contextualwebsearch-websearch-v1.p.rapidapi.com'
    });
    // final res = await rootBundle.loadString('assets/test.json');
    final parsedRes = ImageRes.fromJson(res.body); //res.body
    final filteredImages =
        parsedRes.values.where((img) => img.height == img.width).toList();
    final restImages =
        parsedRes.values.where((img) => img.height != img.width).toList();
    final allImages = [...filteredImages, ...restImages];
    final filteredImageUrls = allImages
        .sublist(0, min(allImages.length, 3))
        .map((img) => img.url)
        .toList();
    return filteredImageUrls;
  }

  Uri _query() {
    return Uri(
      scheme: baseScheme,
      host: baseHost,
      path: basePath,
      queryParameters: {
        "q": _terms,
        "pageNumber": '1',
        "pageSize": '10',
        "autoCorrect": 'true'
      },
    );
  }
}

class ImageRes {
  final String type;
  final int totalCount;
  final List<ImageInstance> values;
  ImageRes(this.type, this.totalCount, this.values);
  factory ImageRes.fromJson(String sjson) {
    final json = jsonDecode(sjson);
    final type = json['_type'];
    final totalCount = json['totalCount'];
    final List<dynamic> jsonValues = json['value'];
    final values = jsonValues.map(ImageInstance.fromJson).toList();
    return ImageRes(type, totalCount, values);
  }
}

class ImageInstance {
  final String url;
  final int height;
  final int width;
  ImageInstance(this.url, this.height, this.width);
  factory ImageInstance.fromJson(dynamic json) {
    final url = json['url'];
    final height = json['height'];
    final width = json['width'];
    return ImageInstance(url, height, width);
  }
}
