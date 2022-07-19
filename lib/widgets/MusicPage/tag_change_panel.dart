import 'package:bottom_drawer/bottom_drawer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../logic/auto_image.dart';
import '../../logic/constants.dart';
import '../../logic/state.dart';
import '../../logic/id3.dart';

class TagChangePanel extends StatefulWidget {
  const TagChangePanel(this.tag, this.tagInx, {Key? key}) : super(key: key);

  final Tag tag;
  final int tagInx;

  @override
  State<TagChangePanel> createState() => _TagChangePanelState();
}

class _TagChangePanelState extends State<TagChangePanel> {
  final imagePicker = GetIt.I.get<ImagePicker>();
  final tracksId = GetIt.I.get<TracksIdentity>();

  final TextEditingController titleControler = TextEditingController();
  final TextEditingController artistControler = TextEditingController();
  final TextEditingController albumControler = TextEditingController();

  late String titleString;
  late String artistString;
  late String albumString;
  late String imageUri;
  late Image tagImage = widget.tag.getImage;
  XFile? pictureFile;

  final BottomDrawerController drawerController = BottomDrawerController();
  bool isDrawerOpen = false;

  late List<String> autoImageUrls = [];

  @override
  void initState() {
    super.initState();
    titleString = widget.tag.title;
    artistString = widget.tag.artist;
    albumString = widget.tag.album;
    imageUri = "";

    titleControler.text = titleString;
    artistControler.text = artistString;
    albumControler.text = albumString;

    titleControler.addListener(() {
      titleString = titleControler.text;
    });
    artistControler.addListener(() {
      artistString = artistControler.text;
    });
    albumControler.addListener(() {
      albumString = albumControler.text;
    });
  }

  pickImage() {
    if (isDrawerOpen) {
      drawerController.close();
    } else {
      drawerController.open();
    }
  }

  pickLocalImage() async {
    drawerController.close();
    pictureFile = await imagePicker.pickImage(source: ImageSource.gallery);
  }

  pickAutoImage() async {
    drawerController.close();
    try {
      final autoImage = AutoImage(widget.tag);
      final imageUrls = await autoImage.getImages();
      setState(() {
        autoImageUrls = imageUrls;
      });
    } catch (error) {
      final snackBar = SnackBar(content: Text(error.toString()));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  saveNewTag() async {
    final Tag tagCp = widget.tag;
    tagCp.title = titleString;
    tagCp.artist = artistString;
    tagCp.album = albumString;

    if (imageUri.isNotEmpty) {
      await tagCp.setPictureFromUri(imageUri);
    } else if (pictureFile != null) {
      await tagCp.setPictureFromFile(pictureFile!);
    }

    Tag.updateWithNewValues(widget.tag, tagCp).then((_) {
      tracksId.current[widget.tagInx] = tagCp;
      Navigator.pop(context);
    });
  }

  saveImage(String uri) async {
    setState(() {
      tagImage = Image.network(uri);
    });
    imageUri = uri;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          Column(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: SizedBox(
                  height: 100.0,
                  width: 100.0,
                  child: FittedBox(
                    clipBehavior: Clip.hardEdge,
                    fit: BoxFit.cover,
                    child: tagImage,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: titleControler,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: artistControler,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: albumControler,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              SizedBox(
                width: 300,
                height: 60,
                child: IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: saveNewTag,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (String uri in autoImageUrls)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: SizedBox(
                        height: 100.0,
                        width: 100.0,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          clipBehavior: Clip.hardEdge,
                          child: GestureDetector(
                            onTap: () => saveImage(uri),
                            child: Image.network(uri),
                          ),
                        ),
                      ),
                    )
                ],
              ),
            ],
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
          BottomDrawer(
            header: Container(),
            color: Colors.transparent,
            body: Row(
              children: [
                ImagePickOption(Icons.folder, pickLocalImage),
                ImagePickOption(Icons.auto_awesome, pickAutoImage),
              ],
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
            ),
            headerHeight: 0.0,
            drawerHeight: gIconDimentions,
            controller: drawerController,
            callback: (draweState) => isDrawerOpen = draweState,
          ),
        ],
      ),
    );
  }
}

class ImagePickOption extends StatelessWidget {
  const ImagePickOption(
    this.iconData,
    this.pickFunc, {
    Key? key,
  }) : super(key: key);
  final IconData iconData;
  final VoidCallback pickFunc;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: Colors.transparent,
        child: InkWell(
          splashColor: Colors.white,
          onTap: pickFunc,
          child: Icon(
            iconData,
          ),
        ),
      ),
    );
  }
}
