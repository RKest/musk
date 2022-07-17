import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../logic/state.dart';
import '../track_list_search_bar.dart';
import '../track_list_controls.dart';

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
