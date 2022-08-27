import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../functions.dart';
import 'id3.dart';
import 'state.dart';

class MyAudioPlayerState {
  Icon playPauseIcon = const Icon(Icons.play_arrow);
  double durationSliderVal = 0.0;
  int totalTrackDuration = 1;
  int currentProgress = 0;
}

class MyAudioPlayer extends BaseAudioHandler {
  final AudioPlayer _audioPlayer = GetIt.I.get<AudioPlayer>();
  final tracksId = GetIt.I.get<TracksIdentity>();
  final currTagId = GetIt.I.get<TagIdentity>();
  final RepeatIconIdentity _repeatIconIdentity = RepeatIconIdentity();

  MyAudioPlayerState myState = MyAudioPlayerState();

  PlayerState _currPlayerState = PlayerState.PAUSED;

  Stream<Duration> get onAudioPositionChanged =>
      _audioPlayer.onAudioPositionChanged;
  Stream<Duration> get onDurationChanged => _audioPlayer.onDurationChanged;
  Stream<PlayerState> get onPlayerStateChanged =>
      _audioPlayer.onPlayerStateChanged;

  MyAudioPlayer() {
    _audioPlayer.onPlayerCompletion.listen((_) {
      playNextTrack(null);
      _updateTrackNotif(currTagId.current);
    });
    _repeatIconIdentity.stream$.listen(setTrackLooping);

    playbackState.add(
      playbackState.value.copyWith(
        systemActions: <MediaAction>{
          MediaAction.seek,
        },
        controls: <MediaControl>[
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
        ],
      ),
    );
  }

  @override
  Future<void> play() async {
    _audioPlayer.resume();
    playbackState.add(
      playbackState.value.copyWith(
        playing: true,
        controls: <MediaControl>[
          MediaControl.skipToPrevious,
          MediaControl.pause,
          MediaControl.skipToNext,
        ],
      ),
    );
    super.play();
  }

  @override
  Future<void> pause() async {
    _audioPlayer.pause();
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        controls: <MediaControl>[
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
        ],
      ),
    );
    super.pause();
  }

  @override
  Future<void> skipToNext() {
    playNextTrack(null);
    _updateTrackNotif(currTagId.current);
    return super.skipToNext();
  }

  @override
  Future<void> skipToPrevious() {
    if (myState.currentProgress > 5000) {
      seekTo(0.0);
    } else {
      playPreviosTrack();
      _updateTrackNotif(currTagId.current);
    }
    return super.skipToPrevious();
  }

  void playPause() {
    if (_currPlayerState == PlayerState.PLAYING) {
      pause();
    } else {
      play();
    }
  }

  void playFromTag(Tag tag) {
    if (tag.mp3Path.isNotEmpty) {
      _updateTrackNotif(tag);
      _audioPlayer.play(tag.mp3Path, isLocal: true, stayAwake: true);
    }
  }

  void seekTo(double value) {
    final seekDuration =
        Duration(milliseconds: (value * myState.totalTrackDuration).toInt());
    _audioPlayer.seek(seekDuration);
    seek(seekDuration);
    play();
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

  static Future<AudioHandler> initAudioService() async {
    return AudioService.init(
      builder: () => MyAudioPlayer(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.musk.channel.audio',
        androidNotificationChannelName: 'Musk',
      ),
    );
  }

  void _updateTrackNotif(Tag tag) {
    final newMediaItem = MediaItem(
      id: tag.mp3Path,
      title: tag.title,
      album: tag.album,
      artist: tag.artist,
    );
    mediaItem.add(newMediaItem);
    playbackState.add(playbackState.value.copyWith(playing: true));
    play();
  }
}
