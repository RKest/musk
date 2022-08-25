import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:musk/logic/audio_player.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../logic/state.dart';
import '../../logic/id3.dart';
import '../../functions.dart';

class CurrentTackPanel extends StatefulWidget {
  const CurrentTackPanel({Key? key}) : super(key: key);

  @override
  State<CurrentTackPanel> createState() => _CurrentTackPanelState();
}

class _CurrentTackPanelState extends State<CurrentTackPanel> {
  final tagId = GetIt.I.get<TagIdentity>();
  final myAudioPlayer = GetIt.I.get<MyAudioPlayer>();

  setTotalTrackDuration(Duration _) {
    myAudioPlayer.setTotalTrackDuration();
    refreshState();
  }

  updateProgress(Duration durationChange) {
    myAudioPlayer.updateProgress(durationChange);
    refreshState();
  }

  setPlayPauseIcon(PlayerState state) {
    myAudioPlayer.setPlayPauseIcon(state);
    refreshState();
  }

  setDurationSliderVal(double value) {
    myAudioPlayer.setDurationSliderVal(value);
    refreshState();
  }

  refreshState() {
    setState(() {
      myAudioPlayer.myState = myAudioPlayer.myState;
    });
  }

  @override
  void initState() {
    super.initState();
    myAudioPlayer.onAudioPositionChanged.listen(updateProgress);
    myAudioPlayer.onDurationChanged.listen(setTotalTrackDuration);
    myAudioPlayer.onPlayerStateChanged.listen(setPlayPauseIcon);
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
                  onPressed: myAudioPlayer.playPause,
                  icon: myAudioPlayer.myState.playPauseIcon,
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
                value: myAudioPlayer.myState.durationSliderVal,
                onChanged: setDurationSliderVal,
                onChangeStart: (_) => myAudioPlayer.pause(),
                onChangeEnd: myAudioPlayer.seekTo,
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
