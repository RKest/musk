import 'package:flutter/material.dart';

import 'id3.dart';
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

enum TrackOrderOptionsEnum { alphabetical, random }

class TracksIdentity {
  final BehaviorSubject<List<Tag>> _tracksIdentity = BehaviorSubject.seeded([]);
  ValueStream<List<Tag>> get stream$ => _tracksIdentity.stream;
  List<Tag> get current => _tracksIdentity.value;

  void setTracks(List<Tag> tagList,
      {TrackOrderOptionsEnum optionsEnum =
          TrackOrderOptionsEnum.alphabetical}) {
    switch (optionsEnum) {
      case TrackOrderOptionsEnum.alphabetical: {
        tagList.sort((t1, t2) => t1.title.compareTo(t2.title));
      }
      break;
      case TrackOrderOptionsEnum.random: {
        tagList.shuffle();
      }
      break;
    }
    _tracksIdentity.add(tagList);
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
