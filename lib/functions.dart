import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'logic/id3.dart';
import 'logic/state.dart';
import 'logic/utils.dart';

void deleteAll() async {
  List<FileSystemEntity> ents = await Utils.scanDir(await Utils.getFilePath);
  for (FileSystemEntity ent in ents) {
    final bool isFile = await FileSystemEntity.isFile(ent.path);
    if (isFile && ent.path.endsWith('.mp3')) {
      await File(ent.path).delete();
    }
  }
}

Stream<List<Tag>> getTags() async* {
  List<Tag> ret = [];
  var ents = await Utils.scanDir(await Utils.getFilePath);
  for (FileSystemEntity ent in ents) {
    final bool isFile = await FileSystemEntity.isFile(ent.path);
    if (isFile && ent.path.endsWith('.mp3')) {
      final Uint8List mp3Bytes = await File(ent.path).readAsBytes();
      final Tag tag = Tag.fromBytes(mp3Bytes, ent.path);
      ret.add(tag);
      yield ret;
    }
  }
}

int? currentTrackIndex() {
  final tracksId = GetIt.I.get<TracksIdentity>();
  final currentTrackId = GetIt.I.get<TagIdentity>();
  if (currentTrackId.current.mp3Path.isEmpty) {
    return null;
  }
  final int currentTrackIndex = tracksId.current.indexWhere(
      (element) => element.mp3Path == currentTrackId.current.mp3Path);
  return currentTrackIndex;
}

void playNextTrack(void _, {bool manualTrackSkip = false}) {
  final tracksId = GetIt.I.get<TracksIdentity>();
  final currentTrackId = GetIt.I.get<TagIdentity>();
  final int? currTrackIndex = currentTrackIndex();
  if ((RepeatIconIdentity.currentRepeatValue != RepeatEnum.repeatOnce ||
          manualTrackSkip) &&
      currTrackIndex != null) {
    if (currTrackIndex == tracksId.current.length - 1) {
      if (RepeatIconIdentity.currentRepeatValue != RepeatEnum.disabled) {
        currentTrackId.changeTrack(tracksId.current[0]);
      }
    } else {
      currentTrackId.changeTrack(tracksId.current[currTrackIndex + 1]);
    }
  }
}

void playPreviosTrack() {
  final tracksId = GetIt.I.get<TracksIdentity>();
  final currentTrackId = GetIt.I.get<TagIdentity>();
  final int? currTrackIndex = currentTrackIndex();
  if (currTrackIndex != null && currTrackIndex != 0) {
    currentTrackId.changeTrack(tracksId.current[currTrackIndex - 1]);
  }
}

void changePage(
    {required BuildContext context,
    required Widget page,
    required VoidCallback cb}) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => page),
  ).then((_) => cb());
}
