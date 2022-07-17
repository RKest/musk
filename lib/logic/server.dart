import 'dart:io';
import 'dart:typed_data';

import 'multipart.dart';
import 'utils.dart';

class Server {
  static String listeningAddress = "";
  static HttpServer? server;
  static Future<String> start() async {
    server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
    String ip = await Utils.localIp ?? "Err while getting the ip";
    listeningAddress = "$ip:${server?.port}";
    return listeningAddress;
  }

  static void listen() async {
    if (server == null) {
      throw "Start the server with Server.start()";
    }

    await for (HttpRequest request in server!) {
      if (request.method == "GET") {
        final String requestPath = request.requestedUri.path;
        if (requestPath.endsWith('.js') || requestPath.endsWith('.css')) {
          request.response
            ..headers.contentType = ContentType(
                "text", requestPath.endsWith('.js') ? "javascript" : "css",
                charset: "utf-8")
            ..write(await Utils.loadAsset(requestPath.replaceAll('/', '')))
            ..close();
        } else {
          request.response
            ..headers.contentType =
                ContentType("text", "html", charset: "utf-8")
            ..write((await Utils.loadAsset('index.html'))
                .replaceFirst('{{}}', listeningAddress))
            ..close();
        }
      } else if (request.method == "POST") {
        final Uint8List data =
            Uint8List.fromList(await request.expand((el) => el).toList());
        final List<int> dataCuffofIndices =
            Multipart.mp3StartAndEndIncides(data);
        final int dataStartIndex = dataCuffofIndices[0];
        final int dataEndIndex = dataCuffofIndices[1];
        final String fileName = Multipart.getFilename(data);
        await Utils.saveToFile(
            fileName, data.sublist(dataStartIndex, dataEndIndex));
        print("Done");
        request.response.close();
      }
    }
  }
}
