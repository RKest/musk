import 'package:flutter/material.dart';

import 'id3.dart';
import 'algs.dart';
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

  void setTracks(List<Tag> tagList){
    _tracksIdentity.add(tagList);
  }

  void shuffleTracks(int? currentTrackIndex){
    if (currentTrackIndex == null){
      current.shuffle();
    }else{
      shuffleExceptPos(current, currentTrackIndex);
    }
    refreshTracks();
  }

  void sortTrackAlphabetically(){
    current.sort((t1, t2) => t1.title.compareTo(t2.title));
    refreshTracks();
  }

  void refreshTracks(){
    setTracks(current);
  }

  void swapTracks(int oldIndex, int newIndex){
    //This if case is beacuse of the error that has not been fixed for few years now
    if (newIndex > oldIndex){
      while(--newIndex - oldIndex != 0){
        swap(current, oldIndex, newIndex);
      }
    } else{
      while(oldIndex - newIndex != 0){
        swap(current, oldIndex, newIndex);
        newIndex++;
      }
    }
  }
}


enum RepeatEnum { disabled, repeat, repeatOnce }
class RepeatIconIdentity {
  static RepeatEnum currentRepeatValue = RepeatEnum.disabled;
  final BehaviorSubject<Icon> _iconIdentity = BehaviorSubject.seeded(const Icon(Icons.repeat));
  ValueStream<Icon> get stream$ => _iconIdentity.stream;
  Icon get current => _iconIdentity.value;

  void incrementIcon(){
    Icon finalIcon;
    currentRepeatValue = RepeatEnum.values[(currentRepeatValue.index + 1) % RepeatEnum.values.length];
    switch (currentRepeatValue ){
      case RepeatEnum.disabled: {
        finalIcon = const Icon(Icons.repeat);
      }
      break;
      case RepeatEnum.repeat: {
        finalIcon = const Icon(Icons.repeat_on_outlined);
      }
      break;
      case RepeatEnum.repeatOnce: {
        finalIcon = const Icon(Icons.repeat_one_on_outlined);
      }
    }
    _iconIdentity.add(finalIcon);
  }
}
