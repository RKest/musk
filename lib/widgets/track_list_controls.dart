import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../logic/state.dart';
import '../logic/constants.dart';
import '../functions.dart';

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
