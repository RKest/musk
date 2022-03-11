import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'utils.dart';
import 'functional.dart';

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
            ..write(await Utils.loadAsset(requestPath.replaceFirst('/', '')))
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
        Stream<Uint8List> brodcast = request.asBroadcastStream();
        brodcast.listen(
          (event) {
            print(event.map((e) => String.fromCharCode(e)).join());
          },
          onDone: () {
            request.response.close();
            print("DONE");
          },
        );
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
