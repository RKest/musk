import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../logic/state.dart';
import '../PlaylistPage/controls.dart';
import '../track_list_controls.dart';
import 'current_track_panel.dart';
import 'track_list.dart';

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
        const CurrentTackPanel(),
      ],
    );
  }
}
