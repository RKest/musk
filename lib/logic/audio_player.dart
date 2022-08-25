import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../functions.dart';
import 'state.dart';

class MyAudioPlayerState {
  Icon playPauseIcon = const Icon(Icons.play_arrow);
  double durationSliderVal = 0.0;
  int totalTrackDuration = 1;
  int currentProgress = 0;
}

class MyAudioPlayer {
  final AudioPlayer _audioPlayer = GetIt.I.get<AudioPlayer>();
  final RepeatIconIdentity _repeatIconIdentity = RepeatIconIdentity();

  MyAudioPlayerState myState = MyAudioPlayerState();

  PlayerState _currPlayerState = PlayerState.PAUSED;

  Stream<Duration> get onAudioPositionChanged =>
      _audioPlayer.onAudioPositionChanged;
  Stream<Duration> get onDurationChanged => _audioPlayer.onDurationChanged;
  Stream<PlayerState> get onPlayerStateChanged =>
      _audioPlayer.onPlayerStateChanged;

  MyAudioPlayer() {
    _audioPlayer.onPlayerCompletion.listen(playNextTrack);
    _repeatIconIdentity.stream$.listen(setTrackLooping);
  }

  void playPause() {
    if (_currPlayerState == PlayerState.PLAYING) {
      pause();
    } else {
      resume();
    }
  }

  void play(String path) {
    if (path.isNotEmpty) {
      _audioPlayer.play(path, isLocal: true, stayAwake: true);
    }
  }

  void resume() {
    _audioPlayer.resume();
  }

  void pause() {
    _audioPlayer.pause();
  }

  void seekTo(double value) {
    _audioPlayer.seek(
        Duration(milliseconds: (value * myState.totalTrackDuration).toInt()));
    resume();
  }

  void setTotalTrackDuration() {
    _audioPlayer.getDuration().then((value) {
      if (value != myState.totalTrackDuration) {
        myState.currentProgress = 0;
        myState.totalTrackDuration = value;
      }
    });
  }

  void updateProgress(Duration duration) {
    myState.currentProgress = duration.inMilliseconds;
    final double currentTrackPostion = myState.currentProgress.toDouble() /
        myState.totalTrackDuration.toDouble();
    myState.durationSliderVal = min(currentTrackPostion, 1.0);
  }

  void setPlayPauseIcon(PlayerState state) {
    _currPlayerState = state;
    if (state == PlayerState.PLAYING) {
      myState.playPauseIcon = const Icon(Icons.pause);
    } else {
      myState.playPauseIcon = const Icon(Icons.play_arrow);
    }
  }

  void setTrackLooping(Icon _) {
    switch (RepeatIconIdentity.currentRepeatValue) {
      case RepeatEnum.disabled:
        _audioPlayer.setReleaseMode(ReleaseMode.STOP);
        break;
      case RepeatEnum.repeat:
        _audioPlayer.setReleaseMode(ReleaseMode.STOP);
        break;
      case RepeatEnum.repeatOnce:
        _audioPlayer.setReleaseMode(ReleaseMode.LOOP);
    }
  }

  void setDurationSliderVal(double value) {
    myState.durationSliderVal = value;
  }
}
