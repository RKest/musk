import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../logic/state.dart';
import '../../logic/playlist.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({Key? key}) : super(key: key);

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final tracksId = GetIt.I.get<TracksIdentity>();
  final pageController = GetIt.I.get<PageController>();
  final newPlaylistIndentity = GetIt.I.get<NewPlaylistIdentity>();
  final isMakingPlaylistIdentity = GetIt.I.get<IsMakingPlaylistIdentity>();

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
