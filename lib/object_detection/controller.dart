import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:permission_handler/permission_handler.dart';

class ObjectController extends GetxController {

  late CameraController cameraController;
  late List<CameraDescription> cameras;

  var isCameraInitialized = false.obs;
  var cameraCount = 0;
  var labelText = "".obs;

  var m = 0.0;
  var y = 0.0;
  var w = 0.0;
  var h = 0.0;

  initialCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();
      cameraController = CameraController(cameras[0], ResolutionPreset.max);
      await cameraController.initialize().then((value) {

        cameraController.startImageStream((image) {
          cameraCount++;
          if (cameraCount % 10 == 0) {
            cameraCount = 0;
            objectDetector(image);
            update();
          }
        });
      });
      isCameraInitialized(true);
      update();
    } else {
      debugPrint("Permission is Denied");
    }
  }

  initTflite() async {
    await Tflite.loadModel(
      model: "assets/mobilenet.tflite",
      labels: "assets/mobilenet.txt",
      isAsset: true,
      numThreads: 1,
      useGpuDelegate: false,
    );
  }


  objectDetector(CameraImage image) async {
    var detector = await Tflite.runModelOnFrame(
      bytesList: image.planes.map((data) => data.bytes).toList(),
      asynch: true, imageHeight: image.height,
      imageWidth: image.width, imageMean: 127.5, imageStd: 127.5,
      numResults: 1, rotation: 90, threshold: 0.4,
    );
    if (detector != null) {
      var data = detector.first;
      labelText.value = data['label'].toString() + data['confidence'].toStringAsFixed(2);
      update();
    }
  }



  @override
  void onInit() {
    initialCamera();
    initTflite();
    super.onInit();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}