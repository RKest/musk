
import 'dart:convert';

import 'package:get_it/get_it.dart';

import 'id3.dart';
import 'state.dart';

class PlaylistJSON {
  PlaylistJSON(this.playlistName, this.mp3Paths);
  final String playlistName;
  final Set<String> mp3Paths;

  static List<PlaylistJSON> listFromJson(String json){
    List<dynamic> jsonList = jsonDecode(json);
    List<PlaylistJSON> ret = [];
    for (var el in jsonList){
      ret.add(PlaylistJSON.fromJson(el));
    }
    return ret;
  }

  factory PlaylistJSON.fromJson(dynamic json){
    final playlistName = json["playlistName"];
    final mp3Paths = List<String>.from(json["mp3Paths"]).toSet();
    return PlaylistJSON(playlistName, mp3Paths);
  }

  Map<String, dynamic> toJson(){
    return {
      "playlistName": playlistName,
      "mp3Paths": mp3Paths.toList()
    };
  }
}

class Playlist {
  late final String playlistName;
  late List<Tag> playlist;
  late TracksIdentity _tracksId;

  Playlist(this.playlistName, List<Tag> trackPaths) {
    _tracksId = GetIt.I.get<TracksIdentity>();
    playlist = trackPaths;
  }

  Playlist.fromJSON(PlaylistJSON playlistJson){
    _tracksId = GetIt.I.get<TracksIdentity>();
    playlistName = playlistJson.playlistName;
    playlist = _tracksId.current
        .where((track) => playlistJson.mp3Paths.contains(track.mp3Path))
        .toList();
  }

  PlaylistJSON playlistJson() {
    return PlaylistJSON(playlistName, playlist.map((e) => e.mp3Path).toSet());
  }
}
