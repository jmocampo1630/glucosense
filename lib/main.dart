import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:glucolook/pages/my_home_page.dart';

import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.camera});
  final CameraDescription camera;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlucoLook',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF37B5B6)),
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'GlucoLook', camera: camera),
      // home: PatientRecordPage(title: 'GlucoLook', camera: camera),
    );
  }
}
