import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../main.dart';


class ObjectDetectionWidget extends StatefulWidget {
  const ObjectDetectionWidget({super.key});
  @override
  State<ObjectDetectionWidget> createState() => _ObjectDetectionWidgetState();
}

class _ObjectDetectionWidgetState extends State<ObjectDetectionWidget> {
  dynamic controller;
  bool isBusy = false;
  dynamic objectDetector;
  late Size size;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  initializeCamera() async {
    try {
      if (cameras.isEmpty) {
        debugPrint("No cameras available");
        return;
      }

      final options = ObjectDetectorOptions(mode: DetectionMode.stream, classifyObjects: true, multipleObjects: true);
      objectDetector = ObjectDetector(options: options);

      controller = CameraController(cameras[0],
        ResolutionPreset.high,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      if (!mounted) return;
      controller.startImageStream((CameraImage image) {

        log('Processing image with format: ${image.format}');
        log('Image metadata: ${image.sensorSensitivity}');

        if (!isBusy) {
          setState(() {
            isBusy = true;
          });
          img = image;
          doObjectDetectionOnFrame();
        }

      });
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    objectDetector.close();
    super.dispose();
  }

  List<DetectedObject> _scanResults = [];
  CameraImage? img;

  doObjectDetectionOnFrame() async {
    InputImage? frameImg = getInputImage();
    if (frameImg != null) {
      List<DetectedObject> objects = await objectDetector.processImage(frameImg);
      debugPrint("len= ${objects.length}");
      setState(() {
        _scanResults = objects;
      });
      isBusy = false;
    }
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? getInputImage() {
    final camera = cameras[0];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
      _orientations[controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(img!.format.raw);
    if (format == null || (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    if (img!.planes.length != 1) return null;
    final plane = img!.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(img!.width.toDouble(), img!.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Widget buildResult() {
    if (_scanResults == null || controller == null || !controller.value.isInitialized) {
      return const Text('');
    }
    final Size imageSize = Size(controller.value.previewSize!.height, controller.value.previewSize!.width);
    CustomPainter painter = ObjectDetectorPainter(imageSize, _scanResults);
    return CustomPaint(painter: painter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:  Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: (controller != null && controller.value.isInitialized) ?
            AspectRatio(aspectRatio: controller.value.aspectRatio, child: CameraPreview(controller)) :
            const Center(child: CircularProgressIndicator()),
          ),
          Positioned(bottom: 10, left: 10, child: buildResult()),
        ],
      ),
    );
  }
}


class ObjectDetectorPainter extends CustomPainter {
  ObjectDetectorPainter(this.absoluteImageSize, this.objects);

  final Size absoluteImageSize;
  final List<DetectedObject> objects;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    final Paint boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.pinkAccent;

    final Paint backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (DetectedObject detectedObject in objects) {
      final Rect boundingBox = Rect.fromLTRB(
        detectedObject.boundingBox.left * scaleX,
        detectedObject.boundingBox.top * scaleY,
        detectedObject.boundingBox.right * scaleX,
        detectedObject.boundingBox.bottom * scaleY,
      );
      canvas.drawRect(boundingBox, boxPaint);

      for (Label label in detectedObject.labels) {
        final String text = "${label.text} (${label.confidence.toStringAsFixed(2)})";

        log("label-text: $text");

        final TextSpan textSpan = TextSpan(text: text, style: const TextStyle(color: Colors.black, fontSize: 14));

        final TextPainter textPainter = TextPainter(text: textSpan, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
        textPainter.layout();
        final Offset textOffset = Offset(boundingBox.left, boundingBox.top - textPainter.height - 4);
        canvas.drawRect(
          Rect.fromLTWH(textOffset.dx - 2, textOffset.dy - 2, textPainter.width + 4, textPainter.height + 4),
          backgroundPaint,
        );
        textPainter.paint(canvas, textOffset);
        break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant ObjectDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.objects != objects;
  }
}