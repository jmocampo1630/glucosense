import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:glucolook/pages/my_home_page.dart';
import 'package:glucolook/services/notification.services.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glucolook/pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize notification service with error handling
  try {
    await NotificationService.initialize();
  } catch (e) {
    // Continue without notifications if initialization fails
    print('Notification initialization failed: $e');
  }

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.camera});
  final CameraDescription camera;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkForNotificationTap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForNotificationTap();
    }
  }

  void _checkForNotificationTap() async {
    final patientId = NotificationService.getAndClearLastTappedPatientId();
    if (patientId != null) {
      // Navigate to the specific patient
      _navigateToPatient(patientId);
    }
  }

  void _navigateToPatient(String patientId) {
    // This will be handled by the home page to navigate to the specific patient
    // We'll pass the patientId to the home page
    final context = navigatorKey.currentContext;
    if (context != null) {
      // You can implement navigation logic here based on your app structure
      // For now, we'll just show a snackbar as an example
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigating to patient: $patientId'),
          backgroundColor: const Color(0xFF37B5B6),
        ),
      );
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'GlucoLook',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF37B5B6)),
        useMaterial3: true,
      ),
      // darkTheme: ThemeData(
      //   brightness: Brightness.dark,
      //   colorScheme: ColorScheme.fromSeed(
      //       seedColor: const Color(0xFF37B5B6), brightness: Brightness.dark),
      //   useMaterial3: true,
      // ),
      themeMode: ThemeMode.system, // Use system theme mode
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return MyHomePage(title: 'GlucoLook', camera: widget.camera);
          }
          return const LoginPage();
        },
      ),
      // home: PatientRecordPage(title: 'GlucoLook', camera: camera),
    );
  }
}
