import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:bottom_drawer/bottom_drawer.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'auto_image.dart';
import 'playlist.dart';
import 'utils.dart';
import 'id3.dart';
import 'state.dart';
import 'server.dart';

const double gTrackDimentions = 70.0;
const double gIconDimentions = 50.0;

void main() {
  GetIt.I.registerSingleton<TagIdentity>(TagIdentity());
  GetIt.I.registerSingleton<AudioPlayer>(AudioPlayer());
  GetIt.I.registerSingleton<TracksIdentity>(TracksIdentity());
  GetIt.I.registerSingleton<ImagePicker>(ImagePicker());
  GetIt.I.registerSingleton<ScrollController>(ScrollController());
  GetIt.I.registerSingleton<PageController>(PageController());
  GetIt.I
      .registerSingleton<IsMakingPlaylistIdentity>(IsMakingPlaylistIdentity());
  GetIt.I.registerSingleton<NewPlaylistIdentity>(NewPlaylistIdentity());
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final pageController = GetIt.I.get<PageController>();
  final tracksId = GetIt.I.get<TracksIdentity>();
  final pages = <Widget>[
    MusicPage(),
    const PlaylistPage(),
  ];
  String listeningAddress = "";
  startServer() async {
    String address = await Server.start();
    setState(() {
      listeningAddress = address;
      print(listeningAddress);
    });
    Server.listen();
  }

  setIndex(int index) {
    setState(() => _currPageIndex = index);
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeIn,
    );
  }

  int _currPageIndex = 0;

  @override
  void initState() {
    startServer();
    super.initState();
  }

  @override
  Widget build(BuildContext mainContext) {
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
          background: Colors.black54,
          onBackground: Colors.deepPurple,
          surface: Colors.black87,
          onSurface: Colors.blueAccent,
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: PageView(
            controller: pageController,
            onPageChanged: (newIndex) =>
                setState(() => _currPageIndex = newIndex),
            children: pages,
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              label: "Queue",
              icon: Icon(Icons.music_note),
            ),
            BottomNavigationBarItem(
              label: "Playlists",
              icon: Icon(Icons.library_music),
            ),
          ],
          currentIndex: _currPageIndex,
          onTap: setIndex,
        ),
        floatingActionButton: const FloatingActionButton(onPressed: deleteAll),
      ),
    );
  }
}

class MusicPage extends StatelessWidget {
  MusicPage({
    Key? key,
  }) : super(key: key);

  final scrollController = GetIt.I.get<ScrollController>();
  final isMakingPlaylistIdentity = GetIt.I.get<IsMakingPlaylistIdentity>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder(
            stream: isMakingPlaylistIdentity.stream$,
            builder: (context, AsyncSnapshot<bool> isCreatingPlaylistSnapshot) {
              if (isCreatingPlaylistSnapshot.data == null ||
                  !isCreatingPlaylistSnapshot.hasData ||
                  !isCreatingPlaylistSnapshot.data!) {
                return TrackListControls();
              } else {
                return PlaylistControls();
              }
            }),
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            physics: const ScrollPhysics(),
            child: const TrackList(),
            controller: scrollController,
          ),
        ),
        const CurrentTackPanel()
      ],
    );
  }
}

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({Key? key}) : super(key: key);

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final tracksId = GetIt.I.get<TracksIdentity>();
  final pageController = GetIt.I.get<PageController>();
  final isMakingPlaylistIdentity = GetIt.I.get<IsMakingPlaylistIdentity>();
  final newPlaylistIndentity = GetIt.I.get<NewPlaylistIdentity>();

  late List<Playlist> playlists = [
    if (tracksId.allTracks.isNotEmpty)
      Playlist("All Tracks", tracksId.allTracks)
  ];
  late List<Image> playlistImages = setPlaylistImages();

  setPlaylistImages() {
    return playlists
        .map((playlist) => playlist.playlist
            .where(
                (track) => track.picture != null && track.picture!.isNotEmpty)
            .first
            .getImage)
        .toList();
  }

  navigateToTracklist() {
    pageController.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeIn,
    );
  }

  String newPlaylistName = "";
  handlePlaylistClick(int tileIndex) async {
    bool isAddPlaylistButton = tileIndex == 0;
    if (isAddPlaylistButton) {
      bool wasPlaylistCreated = await showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text("Name the playlist"),
            content: TextField(
              onChanged: (value) => newPlaylistName = value,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Ok"),
              ),
            ],
          );
        },
      );
      if (wasPlaylistCreated) {
        isMakingPlaylistIdentity.toggle();
        navigateToTracklist();
        newPlaylistIndentity.setPlaylistName(newPlaylistName);
      } else {
        newPlaylistName = "";
      }
    } else {
      tracksId.setTracks(playlists[tileIndex - 1].playlist);
    }
    navigateToTracklist();
  }

  @override
  void initState() {
    super.initState();
    NewPlaylistIdentity.getPlaylists().then((playlist) {
      setState(() {
        playlists = [...playlists, ...playlist];
        playlistImages = setPlaylistImages();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(25.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 50.0,
        mainAxisSpacing: 50.0,
      ),
      itemCount: playlists.length + 1,
      itemBuilder: (context, index) {
        final isFirst = index == 0;
        return Card(
          child: InkWell(
            onTap: () => handlePlaylistClick(index),
            child: Stack(
              children: [
                isFirst
                    ? Image.asset("assets/add.png")
                    : playlistImages[index - 1],
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(bottom: 8.0),
                    constraints: const BoxConstraints.expand(height: 40.0),
                    decoration: const BoxDecoration(color: Colors.black54),
                    child: Text(
                      isFirst
                          ? "Add playlist"
                          : playlists[index - 1].playlistName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PlaylistControls extends StatelessWidget {
  PlaylistControls({Key? key}) : super(key: key);
  final newPlaylistId = GetIt.I.get<NewPlaylistIdentity>();
  final isMakingPlaylistId = GetIt.I.get<IsMakingPlaylistIdentity>();
  final tracksId = GetIt.I.get<TracksIdentity>();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(children: [
          TrackListControl(
            controlIcon: const Icon(Icons.add),
            controlsCallback: () =>
                newPlaylistId.addPaths(tracksId.currentPaths),
          ),
          TrackListControl(
            controlIcon: const Icon(Icons.remove),
            controlsCallback: () =>
                newPlaylistId.removePaths(tracksId.currentPaths),
          ),
          TrackListControl(
            controlIcon: const Icon(Icons.save),
            controlsCallback: () {
              newPlaylistId.savePlaylist();
              isMakingPlaylistId.toggle();
            },
          ),
        ]),
        const Align(
          alignment: Alignment.centerLeft,
          child: TrackListSearchBar(),
        ),
      ],
    );
  }
}

class TrackListControls extends StatelessWidget {
  TrackListControls({Key? key}) : super(key: key);

  final tracksId = GetIt.I.get<TracksIdentity>();
  final scrollController = GetIt.I.get<ScrollController>();
  final repeatIconIdentity = RepeatIconIdentity();

  scrollToCurrentTrack() {
    final currTrackIndex = currentTrackIndex();
    if (currTrackIndex != null) {
      scrollController.animateTo(
        currTrackIndex * gTrackDimentions,
        duration: const Duration(microseconds: 1),
        curve: Curves.linear,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TrackListControl(
          controlIcon: const Icon(Icons.sort_by_alpha),
          controlsCallback: () {
            tracksId.sortTrackAlphabetically();
            scrollToCurrentTrack();
          },
        ),
        TrackListControl(
          controlIcon: const Icon(Icons.shuffle),
          controlsCallback: () {
            final int? currTrackIndex = currentTrackIndex();
            tracksId.shuffleTracks(currTrackIndex);
          },
        ),
        TrackListControl(
          controlIcon: const Icon(Icons.refresh),
          controlsCallback: tracksId.refreshTracks,
        ),
        StreamBuilder(
          builder: (context, AsyncSnapshot<Icon> snapshot) {
            if (snapshot.data == null || !snapshot.hasData) {
              return Container();
            }
            return TrackListControl(
              controlIcon: snapshot.data!,
              controlsCallback: repeatIconIdentity.incrementIcon,
            );
          },
          stream: repeatIconIdentity.stream$,
        ),
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
      child: IconButton(
        icon: controlIcon,
        onPressed: controlsCallback,
      ),
    );
  }
}

class TrackList extends StatefulWidget {
  const TrackList({Key? key}) : super(key: key);

  @override
  State<TrackList> createState() => _TrackListState();
}

class _TrackListState extends State<TrackList>
    with AutomaticKeepAliveClientMixin<TrackList> {
  final audioPlayer = GetIt.I.get<AudioPlayer>();
  final tracksId = GetIt.I.get<TracksIdentity>();
  final currTrackId = GetIt.I.get<TagIdentity>();
  final isMakingPlaylistId = GetIt.I.get<IsMakingPlaylistIdentity>();
  final newPlaylistId = GetIt.I.get<NewPlaylistIdentity>();
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

  trackOnTap(Tag tag) {
    if (isMakingPlaylistId.current) {
      if (newPlaylistId.current.mp3Paths.contains(tag.mp3Path)) {
        newPlaylistId.removePath(tag.mp3Path);
      } else {
        newPlaylistId.addPath(tag.mp3Path);
      }
    } else {
      currTrackId.changeTrack(tag);
    }
  }

  refreshTracks(_) => setState(() => null);
  isEnabled(Tag tag) =>
      !isMakingPlaylistId.current ||
      newPlaylistId.current.mp3Paths.contains(tag.mp3Path);

  @override
  void initState() {
    super.initState();
    getTags().listen(tracksId.initTracks);
    audioPlayer.onPlayerCompletion.listen(playNextTrack);
    repeatIconIdentity.stream$.listen(setTrackLooping);
    currTrackId.stream$.listen(playTrack);
    isMakingPlaylistId.stream$.listen(refreshTracks);
    newPlaylistId.stream$.listen(refreshTracks);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder(
      stream: tracksId.stream$,
      builder: (context, AsyncSnapshot<List<Tag>> snapshot) {
        final tracks = snapshot.data;
        if (tracks == null || tracks.isEmpty) {
          return Container();
        }
        return ReorderableListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: tracksId.swapTracks,
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final Tag tag = tracks[index];
            return AnimatedOpacity(
              key: Key(tag.mp3Path),
              opacity: isEnabled(tag) ? 1.0 : 0.7,
              duration: const Duration(milliseconds: 200),
              child: ListTile(
                onTap: () => trackOnTap(tag),
                visualDensity: const VisualDensity(vertical: -4),
                minVerticalPadding: 0.0,
                contentPadding: const EdgeInsets.all(0.0),
                title: TrackInformations(tag),
                trailing: TrackOptions(tag, index),
              ),
            );
          },
        );
      },
    );
  }
}

class TrackInformations extends StatefulWidget {
  const TrackInformations(this.tag, {Key? key}) : super(key: key);
  final Tag tag;

  @override
  State<TrackInformations> createState() => _TrackInformationsState();
}

class _TrackInformationsState extends State<TrackInformations> {
  late Image trackImage;

  @override
  void initState() {
    super.initState();
    trackImage = widget.tag.getImage;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: gTrackDimentions,
          height: gTrackDimentions,
          child: FittedBox(
            child: trackImage,
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 16.0, 0.0, 0.0),
                child: Text(
                  widget.tag.title,
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
                child: Text(widget.tag.artist),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TrackOptions extends StatelessWidget {
  TrackOptions(this.tag, this.index, {Key? key}) : super(key: key);
  final int index;
  final Tag tag;
  final tracksId = GetIt.I.get<TracksIdentity>();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            changePage(
              context: context,
              page: TagChangePanel(tag, index),
              cb: () async => tracksId.refreshTracks(),
            );
          },
        ),
        ReorderableDragStartListener(
          child: const Icon(Icons.drag_handle),
          index: index,
        ),
      ],
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
  int currentProgress = 0;
  double _durationSliderVal = 0.0;
  Icon playPauseIcon = const Icon(Icons.pause);
  PlayerState currPlayerState = PlayerState.PAUSED;

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
    currPlayerState = state;
    if (state == PlayerState.PLAYING) {
      setState(() {
        playPauseIcon = const Icon(Icons.pause);
      });
    } else {
      setState(() {
        playPauseIcon = const Icon(Icons.play_arrow);
      });
    }
  }

  playPasue() {
    if (currPlayerState == PlayerState.PLAYING) {
      audioPlayer.pause();
    } else {
      audioPlayer.resume();
    }
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
                  icon: const Icon(Icons.fast_rewind),
                ),
                IconButton(
                  onPressed: playPasue,
                  icon: playPauseIcon,
                ),
                IconButton(
                  onPressed: () => playNextTrack(null, manualTrackSkip: true),
                  icon: const Icon(Icons.fast_forward),
                ),
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
            ),
          ],
        );
      },
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
  const TagChangePanel(this.tag, this.tagInx, {Key? key}) : super(key: key);

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
  late String imageUri;
  late Image tagImage = widget.tag.getImage;
  XFile? pictureFile;

  final BottomDrawerController drawerController = BottomDrawerController();
  bool isDrawerOpen = false;

  late List<String> autoImageUrls = [];

  @override
  void initState() {
    super.initState();
    titleString = widget.tag.title;
    artistString = widget.tag.artist;
    albumString = widget.tag.album;
    imageUri = "";

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

  pickImage() {
    if (isDrawerOpen) {
      drawerController.close();
    } else {
      drawerController.open();
    }
  }

  pickLocalImage() async {
    drawerController.close();
    pictureFile = await imagePicker.pickImage(source: ImageSource.gallery);
  }

  pickAutoImage() async {
    drawerController.close();
    try {
      final autoImage = AutoImage(widget.tag);
      final imageUrls = await autoImage.getImages();
      setState(() {
        autoImageUrls = imageUrls;
      });
    } catch (error) {
      print(error);
      final snackBar = SnackBar(content: Text(error.toString()));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  saveNewTag() async {
    final Tag tagCp = widget.tag;
    tagCp.title = titleString;
    tagCp.artist = artistString;
    tagCp.album = albumString;

    if (imageUri.isNotEmpty) {
      print("SET FROM URI");
      await tagCp.setPictureFromUri(imageUri);
    } else if (pictureFile != null) {
      print("SET FROM FILE");
      await tagCp.setPictureFromFile(pictureFile!);
    }

    Tag.updateWithNewValues(widget.tag, tagCp).then((_) {
      tracksId.current[widget.tagInx] = tagCp;
      Navigator.pop(context);
    });
  }

  saveImage(String uri) async {
    print("SAVED URI");
    setState(() {
      tagImage = Image.network(uri);
    });
    imageUri = uri;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          Column(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: SizedBox(
                  height: 100.0,
                  width: 100.0,
                  child: FittedBox(
                    clipBehavior: Clip.hardEdge,
                    fit: BoxFit.cover,
                    child: tagImage,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: titleControler,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: artistControler,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: albumControler,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              SizedBox(
                width: 300,
                height: 60,
                child: IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: saveNewTag,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (String uri in autoImageUrls)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: SizedBox(
                        height: 100.0,
                        width: 100.0,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          clipBehavior: Clip.hardEdge,
                          child: GestureDetector(
                            onTap: () => saveImage(uri),
                            child: Image.network(uri),
                          ),
                        ),
                      ),
                    )
                ],
              ),
            ],
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
          BottomDrawer(
            header: Container(),
            color: Colors.transparent,
            body: Row(
              children: [
                ImagePickOption(Icons.folder, pickLocalImage),
                ImagePickOption(Icons.auto_awesome, pickAutoImage),
              ],
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
            ),
            headerHeight: 0.0,
            drawerHeight: gIconDimentions,
            controller: drawerController,
            callback: (draweState) => isDrawerOpen = draweState,
          ),
        ],
      ),
    );
  }
}

class ImagePickOption extends StatelessWidget {
  const ImagePickOption(
    this.iconData,
    this.pickFunc, {
    Key? key,
  }) : super(key: key);
  final IconData iconData;
  final VoidCallback pickFunc;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: Colors.transparent,
        child: InkWell(
          splashColor: Colors.white,
          onTap: pickFunc,
          child: Icon(
            iconData,
          ),
        ),
      ),
    );
  }
}

class TrackListSearchBar extends StatefulWidget {
  const TrackListSearchBar({Key? key}) : super(key: key);

  @override
  State<TrackListSearchBar> createState() => TrackListSearchBarState();
}

class TrackListSearchBarState extends State<TrackListSearchBar> {
  final tracksId = GetIt.I.get<TracksIdentity>();
  final animationDuration = const Duration(milliseconds: 100);
  final GlobalKey _formKey = GlobalKey();
  final textEditingController = TextEditingController();
  late FocusNode textFieldFocusNode;
  bool isOpen = false;
  toggleIsOpen() async {
    setState(() => isOpen = !isOpen);
    await Future.delayed(animationDuration);
    if (isOpen) {
      textFieldFocusNode.requestFocus();
    } else {
      textFieldFocusNode.unfocus();
    }
  }

  resetText() {
    textEditingController.text = "";
    toggleIsOpen();
  }

  @override
  void initState() {
    super.initState();
    textFieldFocusNode = FocusNode();
    textEditingController.addListener(() {
      String text = textEditingController.text;
      tracksId.filterTracksAccordingToSearch(text);
    });
  }

  @override
  void dispose() {
    textEditingController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchBarWidth = MediaQuery.of(context).size.width;
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        AnimatedContainer(
          alignment: Alignment.centerRight,
          width: isOpen ? searchBarWidth : 0,
          transform:
              Matrix4.translationValues(isOpen ? 0 : searchBarWidth, 0, 0),
          duration: animationDuration,
          height: 40.0,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.0),
            border: Border.all(
              width: 1,
              color: Colors.grey[600]!,
            ),
          ),
          child: TextField(
            key: _formKey,
            focusNode: textFieldFocusNode,
            controller: textEditingController,
            onEditingComplete: toggleIsOpen,
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 20,
            ),
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.fromLTRB(gIconDimentions, 0.0, 0.0, 8.0),
              border: InputBorder.none,
            ),
          ),
        ),
        AnimatedPadding(
          padding: isOpen
              ? EdgeInsets.zero
              : EdgeInsets.only(left: searchBarWidth - gIconDimentions),
          duration: animationDuration,
          child: IconButton(
            color: isOpen ? Colors.grey[600]! : null,
            onPressed: toggleIsOpen,
            icon: const Icon(Icons.search),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: searchBarWidth - gIconDimentions),
          child: AnimatedOpacity(
            opacity: isOpen ? 1 : 0,
            duration: animationDuration,
            child: IconButton(
              icon: const Icon(Icons.close),
              color: Colors.grey[600]!,
              onPressed: resetText,
            ),
          ),
        )
      ],
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

int? currentTrackIndex() {
  final tracksId = GetIt.I.get<TracksIdentity>();
  final currentTrackId = GetIt.I.get<TagIdentity>();
  if (currentTrackId.current.mp3Path.isEmpty) {
    return null;
  }
  final int currentTrackIndex = tracksId.current.indexWhere(
      (element) => element.mp3Path == currentTrackId.current.mp3Path);
  return currentTrackIndex;
}

void playNextTrack(void _, {bool manualTrackSkip = false}) {
  final tracksId = GetIt.I.get<TracksIdentity>();
  final currentTrackId = GetIt.I.get<TagIdentity>();
  final audioPlayer = GetIt.I.get<AudioPlayer>();
  final int? currTrackIndex = currentTrackIndex();
  if ((RepeatIconIdentity.currentRepeatValue != RepeatEnum.repeatOnce ||
          manualTrackSkip) &&
      currTrackIndex != null) {
    if (currTrackIndex == tracksId.current.length - 1) {
      if (RepeatIconIdentity.currentRepeatValue == RepeatEnum.disabled) {
        audioPlayer.release();
      } else {
        currentTrackId.changeTrack(tracksId.current[0]);
      }
    } else {
      currentTrackId.changeTrack(tracksId.current[currTrackIndex + 1]);
    }
  }
}

void playPreviosTrack() {
  final tracksId = GetIt.I.get<TracksIdentity>();
  final currentTrackId = GetIt.I.get<TagIdentity>();
  final int? currTrackIndex = currentTrackIndex();
  if (currTrackIndex != null && currTrackIndex != 0) {
    currentTrackId.changeTrack(tracksId.current[currTrackIndex - 1]);
  }
}

void changePage(
    {required BuildContext context,
    required Widget page,
    required VoidCallback cb}) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => page),
  ).then((_) => cb());
}
