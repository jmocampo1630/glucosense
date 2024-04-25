import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  /// Default Constructor
  const CameraPage({super.key, required this.camera});
  final CameraDescription camera;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController controller;

  @override
  void initState() {
    super.initState();
    controller = CameraController(widget.camera, ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        alignment: FractionalOffset.center,
        children: <Widget>[
          Positioned.fill(
            child:
                AspectRatio(aspectRatio: 1, child: CameraPreview(controller)),
          ),
          Positioned(
            bottom: 20.0,
            child: IconButton(
              onPressed: () async {
                // final imageFile = await controller.takePicture();
                // Navigator.pop(context, imageFile.path);
              },
              icon: const Icon(Icons.camera_alt),
              iconSize: 48.0,
              color: Colors.white,
            ),
          ),
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.blue, // Set the color of the border
                  width: 2.0, // Set the width of the border
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
