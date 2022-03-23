import 'package:rxdart/subjects.dart';

import 'id3.dart';
import 'package:rxdart/rxdart.dart';

class TagIdentity{
  final BehaviorSubject<Tag> _tagSubject = BehaviorSubject.seeded(Tag.fromValues(""));
  ValueStream<Tag> get stream$ => _tagSubject.stream;
  Tag get current => _tagSubject.value;

  void changeTrack(Tag newTag){
    _tagSubject.add(newTag);
  }
}