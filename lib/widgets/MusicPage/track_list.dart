import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../logic/id3.dart';
import '../../logic/state.dart';
import '../../logic/server.dart';
import '../functions.dart';
import 'track_informations.dart';
import 'track_options.dart';

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
  final newPlaylistId = GetIt.I.get<NewPlaylistIdentity>();
  final isMakingPlaylistId = GetIt.I.get<IsMakingPlaylistIdentity>();
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
          return Center(
            child: Text(Server.listeningAddress),
          );
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
