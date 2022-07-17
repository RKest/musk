import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../logic/state.dart';
import '../../logic/id3.dart';
import '../functions.dart';

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
