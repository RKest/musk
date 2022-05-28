import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'utils.dart';
import 'id3.dart';
import 'state.dart';
import 'server.dart';

void main() {
  GetIt.I.registerSingleton<TagIdentity>(TagIdentity());
  GetIt.I.registerSingleton<AudioPlayer>(AudioPlayer());
  GetIt.I.registerSingleton<TracksIdentity>(TracksIdentity());
  GetIt.I.registerSingleton<ImagePicker>(ImagePicker());
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
            onPrimary: Colors.amber,
            onSecondary: Colors.lightGreen,
            error: Colors.red,
            onError: Colors.white70,
            background: Colors.black87,
            onBackground: Colors.deepPurple,
            surface: Colors.black87,
            onSurface: Colors.blueAccent),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Hello world!"),
        ),
        body: Column(
          children: [
            TrackListControls(),
            const Expanded(
              flex: 1,
              child: SingleChildScrollView(
                  physics: ScrollPhysics(), child: TrackList()),
            ),
            const CurrentTackPanel()
          ],
        ),
        floatingActionButton: const FloatingActionButton(onPressed: deleteAll),
      ),
    );
  }
}

class TrackListControls extends StatelessWidget {
  TrackListControls({Key? key}) : super(key: key);

  final tracksId = GetIt.I.get<TracksIdentity>();
  final repeatIconIdentity = RepeatIconIdentity();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TrackListControl(
          controlIcon: const Icon(Icons.sort_by_alpha),
          controlsCallback: () {
            tracksId.setTracks(tracksId.current,
                optionsEnum: TrackOrderOptionsEnum.alphabetical);
          },
        ),
        TrackListControl(
          controlIcon: const Icon(Icons.shuffle),
          controlsCallback: () {
            tracksId.setTracks(tracksId.current,
                optionsEnum: TrackOrderOptionsEnum.random);
          },
        ),
        TrackListControl(
          controlIcon: const Icon(Icons.refresh),
          controlsCallback: () {
            tracksId.setTracks(tracksId.current);
          },
        ),
        StreamBuilder(
          builder: (context, AsyncSnapshot<Icon> snapshot) {
            if (snapshot.data == null || !snapshot.hasData) {
              return Container();
            }
            return TrackListControl(
                controlIcon: snapshot.data!,
                controlsCallback: repeatIconIdentity.incrementIcon);
          },
          stream: repeatIconIdentity.stream$,
        )
      ],
    );
  }
}

class TrackListControl extends StatelessWidget {
  const TrackListControl(
      {Key? key, required this.controlIcon, required this.controlsCallback})
      : super(key: key);

  final Icon controlIcon;
  final VoidCallback controlsCallback;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: IconButton(icon: controlIcon, onPressed: controlsCallback),
    );
  }
}

class TrackList extends StatefulWidget {
  const TrackList({Key? key}) : super(key: key);

  @override
  State<TrackList> createState() => _TrackListState();
}

class _TrackListState extends State<TrackList> {
  final audioPlayer = GetIt.I.get<AudioPlayer>();
  final tracksId = GetIt.I.get<TracksIdentity>();
  final currTrackId = GetIt.I.get<TagIdentity>();
  final RepeatIconIdentity repeatIconIdentity = RepeatIconIdentity();

  setTrackLooping(Icon _) {
    switch (RepeatIconIdentity.currentRepeatValue) {
      case RepeatEnum.disabled:
        audioPlayer.setReleaseMode(ReleaseMode.STOP);
        break;
      case RepeatEnum.repeat:
        audioPlayer.setReleaseMode(ReleaseMode.STOP);
        break;
      case RepeatEnum.repeatOnce:
        audioPlayer.setReleaseMode(ReleaseMode.LOOP);
    }
  }

  playTrack(Tag tag) {
    if (tag.mp3Path.isNotEmpty) {
      audioPlayer.play(tag.mp3Path, isLocal: true, stayAwake: true);
    }
  }

  @override
  void initState() {
    super.initState();
    getTags().listen(tracksId.setTracks);
    audioPlayer.onPlayerCompletion.listen(playNextTrack);
    repeatIconIdentity.stream$.listen(setTrackLooping);
    currTrackId.stream$.listen(playTrack);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder(
            stream: tracksId.stream$,
            builder: (context, AsyncSnapshot<List<Tag>> snapshot) {
              final tracks = snapshot.data;
              if (tracks == null || tracks.isEmpty) {
                return Container();
              }
              return ListView.builder(
                itemCount: tracks.length,
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final Tag tag = tracks[index];
                  return TrackWidget(tag: tag, tagInx: index);
                },
              );
            }),
      ],
    );
  }
}

class TrackWidget extends StatelessWidget {
  TrackWidget({Key? key, required this.tag, required this.tagInx})
      : super(key: key);

  final Tag tag;
  final int tagInx;
  final tracksId = GetIt.I.get<TracksIdentity>();
  final currTrackId = GetIt.I.get<TagIdentity>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => currTrackId.changeTrack(tag),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 65.0,
              width: 65.0,
              child: tag.getImage,
            ),
            TrackInfoWidget(tag: tag),
            IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            TagChangePanel(tag: tag, tagInx: tagInx)),
                  ).then((value) async => tracksId.setTracks(tracksId.current));
                },
                icon: const Icon(Icons.more_vert)),
          ]),
    );
  }
}

class TrackInfoWidget extends StatelessWidget {
  const TrackInfoWidget({
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
  double _durationSliderVal = 0.0;
  Icon playPauseIcon = const Icon(Icons.pause);

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
      final double currentTrackPostion =
          currentProgress.toDouble() / totalTrackDuration.toDouble();
      _durationSliderVal = min(currentTrackPostion, 1.0);
    });
  }

  setPlayPauseIcon(PlayerState state) {
    if (state == PlayerState.PLAYING || state == PlayerState.COMPLETED) {
      setState(() {
        playPauseIcon = const Icon(Icons.pause);
      });
    } else if (state == PlayerState.PAUSED || state == PlayerState.STOPPED) {
      setState(() {
        playPauseIcon = const Icon(Icons.play_arrow);
      });
    }
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
  void initState() {
    super.initState();
    audioPlayer.onAudioPositionChanged.listen(updateProgress);
    audioPlayer.onDurationChanged.listen(setTotalTrackDuration);
    audioPlayer.onPlayerStateChanged.listen(setPlayPauseIcon);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
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
                      onPressed: () => playPreviosTrack(),
                      icon: const Icon(Icons.fast_rewind)),
                  IconButton(onPressed: playPasue, icon: playPauseIcon),
                  IconButton(
                      onPressed: () =>
                          playNextTrack(null, manualTrackSkip: true),
                      icon: const Icon(Icons.fast_forward)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0),
                child: Slider(
                  value: _durationSliderVal,
                  onChanged: (value) {
                    setState(() {
                      _durationSliderVal = value;
                    });
                  },
                  onChangeStart: (_) {
                    audioPlayer.pause();
                  },
                  onChangeEnd: (val) {
                    audioPlayer.seek(Duration(
                        milliseconds: (val * totalTrackDuration).toInt()));
                    audioPlayer.resume();
                  },
                ),
              )
            ],
          );
        });
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
    return Expanded(
      flex: 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 16.0, 0.0, 0.0),
            child: Text(
              tag.title,
              maxLines: 1,
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

class TagChangePanel extends StatefulWidget {
  const TagChangePanel({required this.tag, required this.tagInx, Key? key})
      : super(key: key);

  final Tag tag;
  final int tagInx;

  @override
  State<TagChangePanel> createState() => _TagChangePanelState();
}

class _TagChangePanelState extends State<TagChangePanel> {
  final imagePicker = GetIt.I.get<ImagePicker>();
  final tracksId = GetIt.I.get<TracksIdentity>();

  final TextEditingController titleControler = TextEditingController();
  final TextEditingController artistControler = TextEditingController();
  final TextEditingController albumControler = TextEditingController();

  late String titleString;
  late String artistString;
  late String albumString;
  XFile? pictureFile;

  @override
  void initState() {
    super.initState();
    titleString = widget.tag.title;
    artistString = widget.tag.artist;
    albumString = widget.tag.album;

    titleControler.text = titleString;
    artistControler.text = artistString;
    albumControler.text = albumString;

    titleControler.addListener(() {
      titleString = titleControler.text;
    });
    artistControler.addListener(() {
      artistString = artistControler.text;
    });
    albumControler.addListener(() {
      albumString = albumControler.text;
    });
  }

  pickImage() async {
    pictureFile = await imagePicker.pickImage(source: ImageSource.gallery);
  }

  saveNewTag() async {
    final Tag tagCp = widget.tag;
    tagCp.title = titleString;
    tagCp.artist = artistString;
    tagCp.album = albumString;
    if (pictureFile != null) {
      tagCp.setPicture(pictureFile!);
    }
    Tag.updateWithNewValues(widget.tag, tagCp).then((_) {
      tracksId.current[widget.tagInx] = tagCp;
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          GestureDetector(
            onTap: pickImage,
            child: SizedBox(
              height: 100.0,
              width: 100.0,
              child: widget.tag.getImage,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: titleControler,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: artistControler,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: albumControler,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          SizedBox(
            width: 300,
            height: 60,
            child: IconButton(
              icon: const Icon(Icons.save),
              onPressed: saveNewTag,
            ),
          )
        ],
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
    );
  }
}

void deleteAll() async {
  List<FileSystemEntity> ents = await Utils.scanDir(await Utils.getFilePath);
  for (FileSystemEntity ent in ents) {
    final bool isFile = await FileSystemEntity.isFile(ent.path);
    if (isFile && ent.path.endsWith('.mp3')) {
      await File(ent.path).delete();
    }
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

void playNextTrack(void _, {bool manualTrackSkip = false}) {
  final tracksId = GetIt.I.get<TracksIdentity>();
  final currentTrackId = GetIt.I.get<TagIdentity>();
  final audioPlayer = GetIt.I.get<AudioPlayer>();
  if (RepeatIconIdentity.currentRepeatValue != RepeatEnum.repeatOnce ||
      manualTrackSkip) {
    final int currentTrackIndex = tracksId.current.indexWhere(
        (element) => element.mp3Path == currentTrackId.current.mp3Path);
    if (currentTrackIndex == tracksId.current.length - 1) {
      if (RepeatIconIdentity.currentRepeatValue == RepeatEnum.disabled) {
        audioPlayer.release();
      } else {
        currentTrackId.changeTrack(tracksId.current[0]);
      }
    } else {
      currentTrackId.changeTrack(tracksId.current[currentTrackIndex + 1]);
    }
  }
}

void playPreviosTrack() {
  final tracksId = GetIt.I.get<TracksIdentity>();
  final currentTrackId = GetIt.I.get<TagIdentity>();
  final int currentTrackIndex = tracksId.current.indexWhere(
      (element) => element.mp3Path == currentTrackId.current.mp3Path);
  if (currentTrackIndex != 0) {
    currentTrackId.changeTrack(tracksId.current[currentTrackIndex - 1]);
  }
}
