import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musk/playlist.dart';

import 'id3.dart';
import 'algs.dart';
import 'utils.dart';
import 'package:rxdart/rxdart.dart';

class TagIdentity {
  final BehaviorSubject<Tag> _tagSubject =
      BehaviorSubject.seeded(Tag.fromValues(""));
  ValueStream<Tag> get stream$ => _tagSubject.stream;
  Tag get current => _tagSubject.value;

  void changeTrack(Tag newTag) {
    _tagSubject.add(newTag);
  }
}

class TracksIdentity {
  final BehaviorSubject<List<Tag>> _tracksIdentity = BehaviorSubject.seeded([]);
  ValueStream<List<Tag>> get stream$ => _tracksIdentity.stream;
  List<Tag> get current => _tracksIdentity.value;
  List<Tag> _allTracks = [];
  List<String> get currentPaths =>
      current.map((track) => track.mp3Path).toList();
  List<Tag> get allTracks => _allTracks;

  void initTracks(List<Tag> tagList) {
    _allTracks = tagList;
    setTracks(_allTracks);
  }

  void setTracks(List<Tag> tagList) {
    _tracksIdentity.add(tagList);
  }

  void shuffleTracks(int? currentTrackIndex) {
    if (currentTrackIndex == null) {
      current.shuffle();
    } else {
      shuffleExceptPos(current, currentTrackIndex);
    }
    refreshTracks();
  }

  void sortTrackAlphabetically() {
    current.sort((t1, t2) => t1.title.compareTo(t2.title));
    refreshTracks();
  }

  void refreshTracks() {
    setTracks(current);
  }

  void swapTracks(int oldIndex, int newIndex) {
    //This if case is beacuse of the error that has not been fixed for few years now
    if (newIndex > oldIndex) {
      while (--newIndex - oldIndex != 0) {
        swap(current, oldIndex, newIndex);
      }
    } else {
      while (oldIndex - newIndex != 0) {
        swap(current, oldIndex, newIndex);
        newIndex++;
      }
    }
  }

  void filterTracksAccordingToSearch(String searchTerm) {
    setTracks(_allTracks
        .where((tag) => _matchesSearchTerm(searchTerm, tag))
        .toList());
  }

  bool _matchesSearchTerm(String searchTerm, Tag tag) {
    if (searchTerm.isEmpty) return true;
    searchTerm = searchTerm.toLowerCase();
    final bool matchesTitle = tag.title.toLowerCase().contains(searchTerm);
    final bool matchesAlbum = tag.album.toLowerCase().contains(searchTerm);
    final bool matchesAuthor = tag.artist.toLowerCase().contains(searchTerm);
    return matchesTitle || matchesAlbum || matchesAuthor;
  }
}

enum RepeatEnum { disabled, repeat, repeatOnce }

class RepeatIconIdentity {
  static RepeatEnum currentRepeatValue = RepeatEnum.disabled;
  final BehaviorSubject<Icon> _iconIdentity =
      BehaviorSubject.seeded(const Icon(Icons.repeat));
  ValueStream<Icon> get stream$ => _iconIdentity.stream;
  Icon get current => _iconIdentity.value;

  void incrementIcon() {
    Icon finalIcon;
    currentRepeatValue = RepeatEnum
        .values[(currentRepeatValue.index + 1) % RepeatEnum.values.length];
    switch (currentRepeatValue) {
      case RepeatEnum.disabled:
        {
          finalIcon = const Icon(Icons.repeat);
        }
        break;
      case RepeatEnum.repeat:
        {
          finalIcon = const Icon(Icons.repeat_on_outlined);
        }
        break;
      case RepeatEnum.repeatOnce:
        {
          finalIcon = const Icon(Icons.repeat_one_on_outlined);
        }
    }
    _iconIdentity.add(finalIcon);
  }
}

class IsMakingPlaylistIdentity {
  final BehaviorSubject<bool> _isMakingPlaylistIdentity =
      BehaviorSubject.seeded(false);
  ValueStream<bool> get stream$ => _isMakingPlaylistIdentity.stream;
  bool get current => _isMakingPlaylistIdentity.value;

  void toggle() {
    _isMakingPlaylistIdentity.add(!current);
  }
}

class NewPlaylistIdentity {
  static const playlistJsonFileName = "/playlists.json";
  final BehaviorSubject<PlaylistJSON> _newPlaylistIdentity =
      BehaviorSubject.seeded(PlaylistJSON("", {}));
  ValueStream<PlaylistJSON> get stream$ => _newPlaylistIdentity.stream;
  PlaylistJSON get current => _newPlaylistIdentity.value;

  void setPlaylistName(String name) {
    _newPlaylistIdentity.add(PlaylistJSON(name, {}));
  }

  void setPlaylist(String name, Set<String> paths) {
    _newPlaylistIdentity.add(PlaylistJSON(name, paths));
  }

  void refreshPlaylists() {
    setPlaylist(current.playlistName, current.mp3Paths);
  }

  void clearPlaylist() {
    setPlaylist(current.playlistName, {});
  }

  void removePaths(List<String> paths) {
    current.mp3Paths.removeAll(paths);
    refreshPlaylists();
  }

  void addPaths(List<String> paths) {
    current.mp3Paths.addAll(paths);
    refreshPlaylists();
  }

  void removePath(String path) {
    current.mp3Paths.remove(path);
    refreshPlaylists();
  }

  void addPath(String path) {
    current.mp3Paths.add(path);
    refreshPlaylists();
  }

  void savePlaylist() async {
    final documentsPath = await Utils.getFilePath;
    final fullJsonPath = "$documentsPath$playlistJsonFileName";
    final File jsonPlaylistFile = File(fullJsonPath);
    final bool hasThereBeenAnyPlaylists = await jsonPlaylistFile.exists();
    final List<PlaylistJSON> allPlaylistJsons = hasThereBeenAnyPlaylists
        ? jsonDecode(await jsonPlaylistFile.readAsString())
        : [];
    allPlaylistJsons.add(current);
    final String jsonString = jsonEncode(allPlaylistJsons);
    await jsonPlaylistFile.writeAsString(jsonString);
  }

  static Future<List<Playlist>> getPlaylists() async {
    final documentsPath = await Utils.getFilePath;
    final fullJsonPath = "$documentsPath$playlistJsonFileName";
    final File jsonPlaylistFile = File(fullJsonPath);
    final bool hasThereBeenAnyPlaylists = await jsonPlaylistFile.exists();
    final List<PlaylistJSON> allPlaylistJsons = hasThereBeenAnyPlaylists
        ? PlaylistJSON.listFromJson(await jsonPlaylistFile.readAsString())
        : [];
    final List<Playlist> allPlaylists =
        allPlaylistJsons.map(Playlist.fromJSON).toList();
    return allPlaylists;
  }
}
