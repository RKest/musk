import '../../logic/id3.dart';
import '../../logic/constants.dart';
import 'package:flutter/material.dart';

class TrackInformations extends StatefulWidget {
  const TrackInformations(this.tag, {Key? key}) : super(key: key);
  final Tag tag;

  @override
  State<TrackInformations> createState() => _TrackInformationsState();
}

class _TrackInformationsState extends State<TrackInformations> {
  late Image trackImage;

  @override
  void initState() {
    super.initState();
    trackImage = widget.tag.getImage;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: gTrackDimentions,
          height: gTrackDimentions,
          child: FittedBox(
            child: trackImage,
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 16.0, 0.0, 0.0),
                child: Text(
                  widget.tag.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0.0, 0.0, 0.0),
                child: Text(widget.tag.artist),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
