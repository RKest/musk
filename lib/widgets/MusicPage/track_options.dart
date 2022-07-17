import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import '../../logic/state.dart';
import '../../logic/id3.dart';
import '../functions.dart';
import 'tag_change_panel.dart';

class TrackOptions extends StatelessWidget {
  TrackOptions(this.tag, this.index, {Key? key}) : super(key: key);
  final int index;
  final Tag tag;
  final tracksId = GetIt.I.get<TracksIdentity>();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            changePage(
              context: context,
              page: TagChangePanel(tag, index),
              cb: () async => tracksId.refreshTracks(),
            );
          },
        ),
        ReorderableDragStartListener(
          child: const Icon(Icons.drag_handle),
          index: index,
        ),
      ],
    );
  }
}
