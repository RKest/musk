import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:get_it/get_it.dart';
import 'package:marquee/marquee.dart';
import 'utils.dart';
import 'id3.dart';
import 'state.dart';
import 'server.dart';

void main() {
  GetIt.I.registerSingleton<TagIdentity>(TagIdentity());
  GetIt.I.registerSingleton<AudioPlayer>(AudioPlayer());
  GetIt.I.registerSingleton<TracksIdentity>(TracksIdentity());
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String listeningAddress = "";
  startServer() async {
    String address = await Server.start();
    setState(() {
      listeningAddress = address;
    });
    Server.listen();
  }

  @override
  Widget build(BuildContext mainContext) {
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
        body: Column(
          children: const [
            TrackListWidget(),
            CurrentTackPanel(),
          ],
          mainAxisSize: MainAxisSize.max,
        ),
        floatingActionButton: const FloatingActionButton(onPressed: deleteAll),
      ),
    );
  }
}

Stream<List<Tag>> getTags() async* {
  List<Tag> ret = [];
  var ents = await Utils.scanDir(await Utils.getFilePath);

  for (FileSystemEntity ent in ents) {
    final bool isFile = await FileSystemEntity.isFile(ent.path);
    if (isFile && ent.path.endsWith('.mp3')) {
      final Uint8List mp3Bytes = await File(ent.path).readAsBytes();
      final Tag tag = Tag.fromBytes(mp3Bytes, ent.path);
      ret.add(tag);
      yield ret;
    }
  }
}

class MainListTrack extends StatelessWidget {
  const MainListTrack({
    Key? key,
    required this.tag,
  }) : super(key: key);

  final Tag tag;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => playTrack(tag),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 60.0,
              width: 60.0,
              child: tag.getImage,
            ),
            MainTrackListInfo(tag: tag),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TagChangePanel(tag: tag)),
                );
              },
              icon: const Icon(Icons.more_vert)
            ),
          ]),
    );
  }
}

class MainTrackListInfo extends StatelessWidget {
  const MainTrackListInfo({
    Key? key,
    required this.tag,
  }) : super(key: key);

  final Tag tag;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 16.0, 0.0, 0.0),
            child: Text(
              tag.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0.0, 0.0, 0.0),
            child: Text(tag.artist),
          )
        ],
      ),
    );
  }
}

class CurrentTackPanel extends StatefulWidget {
  const CurrentTackPanel({Key? key}) : super(key: key);

  @override
  State<CurrentTackPanel> createState() => _CurrentTackPanelState();
}

class _CurrentTackPanelState extends State<CurrentTackPanel> {
  final tagId = GetIt.I.get<TagIdentity>();
  final audioPlayer = GetIt.I.get<AudioPlayer>();

  int totalTrackDuration = 1;
  bool isPaused = false;
  int currentProgress = 0;
  playPauseIcon() {
    return Icon(isPaused ? Icons.play_arrow : Icons.pause);
  }

  setTotalTrackDuration(Duration _) {
    audioPlayer.getDuration().then((value) {
      if (value != totalTrackDuration) {
        setState(() {
          currentProgress = 0;
          totalTrackDuration = value;
        });
      }
    });
  }

  updateProgress(Duration durationChange) {
    setState(() {
      currentProgress = durationChange.inMilliseconds;
    });
  }

  playPasue() {
    if (isPaused) {
      audioPlayer.resume();
    } else {
      audioPlayer.pause();
    }
    setState(() {
      isPaused = !isPaused;
    });
  }

  @override
  Widget build(BuildContext context) {
    audioPlayer.onAudioPositionChanged.listen(updateProgress);
    audioPlayer.onDurationChanged.listen(setTotalTrackDuration);
    return Expanded(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: StreamBuilder(
            stream: tagId.stream$,
            builder: (context, AsyncSnapshot<Tag> snapshot) {
              final tag = snapshot.data;
              if (tag == null || tag.mp3Path.isEmpty) {
                return Container();
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CurrentTrackPanelInfo(tag: tag),
                      IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.fast_rewind)),
                      IconButton(
                        onPressed: playPasue, 
                        icon: playPauseIcon()),
                      IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.fast_forward)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0),
                    child: Slider(
                        value: currentProgress.toDouble() / totalTrackDuration.toDouble(),
                        onChanged: (change) {}),
                  )
                ],
              );
            }),
      ),
    );
  }
}

class CurrentTrackPanelInfo extends StatelessWidget {
  const CurrentTrackPanelInfo({
    Key? key,
    required this.tag,
  }) : super(key: key);

  final Tag tag;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
    );
  }
}

class TrackListWidget extends StatefulWidget {
  const TrackListWidget({Key? key}) : super(key: key);

  @override
  State<TrackListWidget> createState() => _TrackListWidgetState();
}

class _TrackListWidgetState extends State<TrackListWidget> {
  final tracksId = GetIt.I.get<TracksIdentity>();
  final tagStream = getTags();
  void loadTags() async {
    tagStream.listen((event) => tracksId.setTracks(event));
  }

  @override
  Widget build(BuildContext context) {
    loadTags();
    return StreamBuilder(
        stream: tracksId.stream$,
        builder: (context, AsyncSnapshot<List<Tag>> snapshot) {
          final tracks = snapshot.data;
          if (tracks == null || tracks.isEmpty) {
            return Container();
          }
          return ListView.builder(
              itemCount: tracks.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final Tag tag = tracks[index];
                return MainListTrack(tag: tag);
              });
        });
  }
}

class TagChangePanel extends StatelessWidget {
  const TagChangePanel({ required this.tag, Key? key }) : super(key: key);

  final Tag tag;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Text("Hello World")
      ],
      mainAxisSize: MainAxisSize.max,
    );
  }
}

void playTrack(Tag tag) {
  final audioPlayer = GetIt.I.get<AudioPlayer>();
  final tagId = GetIt.I.get<TagIdentity>();
  tagId.changeTrack(tag);
  audioPlayer.play(tag.mp3Path);
}

void deleteAll() async {
  List<FileSystemEntity> ents = await Utils.scanDir(await Utils.getFilePath);
  for (FileSystemEntity ent in ents) {
    final bool isFile = await FileSystemEntity.isFile(ent.path);
    if (isFile && ent.path.endsWith('.mp3')) {
      print("Deleted ${ent.path}");
      await File(ent.path).delete();
    }
  }
}
