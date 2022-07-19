import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'logic/state.dart';
import 'logic/server.dart';

import 'widgets/MusicPage/main.dart';
import 'widgets/PlaylistPage/main.dart';
import 'widgets/functions.dart';

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
  startServer() async {
    String address = await Server.start();
    setState(() {
      Server.listeningAddress = address;
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
