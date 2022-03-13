import 'dart:io';
import 'dart:typed_data';

import 'package:audiotagger/models/tag.dart';
import 'package:flutter/material.dart';
import 'multipart.dart';
import 'utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String fileContents = "";
  String listeningAddress = "";

  final myController = TextEditingController();

  startServer() async {
    var ents = await Utils.scanDir(await Utils.getFilePath);

    for (FileSystemEntity ent in ents) {
      final bool isFile = await FileSystemEntity.isFile(ent.path);
      if (isFile && ent.path.endsWith('.mp3')) {
        print('Ent: $ent');
        final Tag tags = await Utils.getTags(ent.path);
        print('Tags: $tags');
      }
    }

    var server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
    String ip = await Utils.localIp ?? "Err while getting the ip";
    setState(() {
      listeningAddress = "$ip:${server.port}";
    });
    await for (HttpRequest request in server) {
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
        bool isFirst = true;
        String fileName = "Err";
        Stream<Uint8List> brodcast = request.asBroadcastStream();
        await for (Uint8List event in brodcast) {
          if (isFirst) {
            fileName = Multipart.getFilename(event);
            print('Starting: $fileName');
            isFirst = false;
          }
          Utils.saveToFile(fileName, event);
        }
        print("Done");
        request.response.close();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    startServer();
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.cyan,
          title: const Text("Hello world!"),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: myController,
            ),
            TextButton(
              onPressed: () {
                // Utils.saveToFile(myController.text);
              },
              child: const Text("Save to file"),
            ),
            TextButton(
              onPressed: () {
                // Utils.readFromFile().then((contents) {
                //   setState(() {
                //     fileContents = contents;
                //   });
                // });
              },
              child: const Text("Read from file"),
            ),
            Text(fileContents),
            Text(listeningAddress),
          ],
        ),
      ),
    );
  }
}
