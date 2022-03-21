import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'multipart.dart';
import 'utils.dart';
import 'id3.dart';

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
  final AudioPlayer audioPlayer = AudioPlayer();

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
        final int dataStartIndex = Multipart.mp3DataStartIndex(data);
        final String fileName = Multipart.getFilename(data);
        await Utils.saveToFile(fileName, data.sublist(dataStartIndex));
        print("Done");
        request.response.close();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    startServer();
    return MaterialApp(
      theme: ThemeData(
        colorScheme: const ColorScheme(
            primary: Colors.black87,
            secondary: Color.fromRGBO(15, 60, 180, 1),
            brightness: Brightness.dark,
            onPrimary: Colors.white70,
            onSecondary: Colors.white70,
            error: Colors.red,
            onError: Colors.white70,
            background: Colors.black87,
            onBackground: Colors.white70,
            surface: Colors.black87,
            onSurface: Colors.white70),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Hello world!"),
        ),
        body: trackListWidget(audioPlayer),
        floatingActionButton: const FloatingActionButton(onPressed: deleteAll),
      ),
    );
  }
}

Future<List<Tag>> getTags() async {
  List<Tag> ret = [];
  var ents = await Utils.scanDir(await Utils.getFilePath);

  for (FileSystemEntity ent in ents) {
    final bool isFile = await FileSystemEntity.isFile(ent.path);
    if (isFile && ent.path.endsWith('.mp3')) {
      final Uint8List mp3Bytes = await File(ent.path).readAsBytes();
      final Tag tag = Tag.fromBytes(mp3Bytes, ent.path);
      ret.add(tag);
    }
  }
  return ret;
}

Widget trackListWidget(AudioPlayer audioPlayer) {
  return FutureBuilder(
    builder: (context, AsyncSnapshot<List<Tag>> trackSnap) {
      if (trackSnap.connectionState == ConnectionState.none ||
          !trackSnap.hasData) {
        return Container();
      }
      return ListView.builder(
          itemCount: trackSnap.data?.length,
          itemBuilder: (context, index) {
            final Tag tag = trackSnap.data![index];
            return GestureDetector(
              onTap: () => audioPlayer.play(tag.mp3Path, isLocal: true),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 80.0,
                      width: 80.0,
                      child: getSongImage(tag),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 16.0, 0.0, 0.0),
                          child: Text(
                            tag.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 0.0, 0.0, 0.0),
                          child: Text(tag.artist),
                        )
                      ],
                    ),
                  ]),
            );
          });
    },
    future: getTags(),
  );
}

Image getSongImage(Tag tag) {
  if (tag.picture != null && tag.picture!.isNotEmpty) {
    return Image.memory(tag.picture!);
  } else {
    return Image.asset("assets/def.png");
  }
}

void deleteAll() async {
  var ents = await Utils.scanDir(await Utils.getFilePath);

  for (FileSystemEntity ent in ents) {
    final bool isFile = await FileSystemEntity.isFile(ent.path);
    if (isFile && ent.path.endsWith('.mp3')) {
      print("Deleted ${ent.path}");
      await File(ent.path).delete();
    }
  }
}
