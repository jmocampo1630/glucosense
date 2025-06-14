import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class CameraPage extends StatefulWidget {
  /// Default Constructor
  const CameraPage({super.key, required this.camera});
  final CameraDescription camera;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController controller;
  bool _isFlashOn = false;

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
        title: const Text('Scan Glucose Level'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        alignment: FractionalOffset.center,
        children: <Widget>[
          Positioned.fill(
            child: CameraPreview(controller),
          ),
          Positioned(
            bottom: 25.0,
            left: 70.0,
            child: IconButton(
              onPressed: _toggleFlash,
              icon: Icon(
                _isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
                size: 48.0,
              ),
            ),
          ),
          Positioned(
            bottom: 25.0,
            right: 70.0,
            child: IconButton(
              onPressed: () => _takePictureAndNavigateBack(context, controller),
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
                  color: Colors.blue,
                  width: 2.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFlash() async {
    final FlashMode newFlashMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
    try {
      await controller.setFlashMode(newFlashMode);
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }
}

Future<void> _takePictureAndNavigateBack(
    BuildContext context, CameraController controller) async {
  try {
    final imageFile = await controller.takePicture();

    img.Image? image = img.decodeImage(File(imageFile.path).readAsBytesSync());
    if (image == null) return;

    const imgSize = 200;
    int x = (image.width - imgSize) ~/ 2;
    int y = (image.height - imgSize) ~/ 2;

    // Crop the image
    img.Image croppedImage = img.copyCrop(image, x, y, imgSize, imgSize);

    // Save the cropped image to a temporary file
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    DateTime now = DateTime.now();
    String timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    File tempFile = File('$tempPath/cropped_image$timestamp.png');
    await tempFile.writeAsBytes(img.encodePng(croppedImage));

    if (!context.mounted) return;
    Navigator.pop(context, tempFile.path);
  } catch (e) {
    // print('Error capturing image: $e');
  }
}
