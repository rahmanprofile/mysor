import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hyler/image_labeling/image_labeling_from_camera.dart';
import 'face_detection/face_detector_view.dart';
import 'image_labeling/image_labeling_from_gallery.dart';

late List<CameraDescription> cameras;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const Home(),
      debugShowCheckedModeBanner: false,
      title: 'Flutter Face Detection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}


class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            button(
                context: context,
                title: "Face Detection",
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FaceDetectorView()));
                },
            ),
            const SizedBox(height: 10),
            button(
              context: context,
              title: "Camera Image Labeling",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ImageLabelingFromCamera()));
              },
            ),
            const SizedBox(height: 10),
            button(
              context: context,
              title: "Gallery Image Labeling",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ImageLabelingFromGallery()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget button({required BuildContext context, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: MediaQuery.of(context).size.width / 2,
        color: CupertinoColors.activeOrange,
        child: Center(
          child: Text(title, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
