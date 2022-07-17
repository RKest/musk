import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../logic/constants.dart';
import '../logic/state.dart';

class TrackListSearchBar extends StatefulWidget {
  const TrackListSearchBar({Key? key}) : super(key: key);

  @override
  State<TrackListSearchBar> createState() => TrackListSearchBarState();
}

class TrackListSearchBarState extends State<TrackListSearchBar> {
  final tracksId = GetIt.I.get<TracksIdentity>();
  final animationDuration = const Duration(milliseconds: 100);
  final GlobalKey _formKey = GlobalKey();
  final textEditingController = TextEditingController();
  late FocusNode textFieldFocusNode;
  bool isOpen = false;
  toggleIsOpen() async {
    setState(() => isOpen = !isOpen);
    await Future.delayed(animationDuration);
    if (isOpen) {
      textFieldFocusNode.requestFocus();
    } else {
      textFieldFocusNode.unfocus();
    }
  }

  resetText() {
    textEditingController.text = "";
    toggleIsOpen();
  }

  @override
  void initState() {
    super.initState();
    textFieldFocusNode = FocusNode();
    textEditingController.addListener(() {
      String text = textEditingController.text;
      tracksId.filterTracksAccordingToSearch(text);
    });
  }

  @override
  void dispose() {
    textEditingController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchBarWidth = MediaQuery.of(context).size.width;
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        AnimatedContainer(
          alignment: Alignment.centerRight,
          width: isOpen ? searchBarWidth : 0,
          transform:
              Matrix4.translationValues(isOpen ? 0 : searchBarWidth, 0, 0),
          duration: animationDuration,
          height: 40.0,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.0),
            border: Border.all(
              width: 1,
              color: Colors.grey[600]!,
            ),
          ),
          child: TextField(
            key: _formKey,
            focusNode: textFieldFocusNode,
            controller: textEditingController,
            onEditingComplete: toggleIsOpen,
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 20,
            ),
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.fromLTRB(gIconDimentions, 0.0, 0.0, 8.0),
              border: InputBorder.none,
            ),
          ),
        ),
        AnimatedPadding(
          padding: isOpen
              ? EdgeInsets.zero
              : EdgeInsets.only(left: searchBarWidth - gIconDimentions),
          duration: animationDuration,
          child: IconButton(
            color: isOpen ? Colors.grey[600]! : null,
            onPressed: toggleIsOpen,
            icon: const Icon(Icons.search),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: searchBarWidth - gIconDimentions),
          child: AnimatedOpacity(
            opacity: isOpen ? 1 : 0,
            duration: animationDuration,
            child: IconButton(
              icon: const Icon(Icons.close),
              color: Colors.grey[600]!,
              onPressed: resetText,
            ),
          ),
        )
      ],
    );
  }
}
