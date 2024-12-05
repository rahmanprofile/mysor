import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'image_controller.dart';

class ImageLabelingFromGallery extends StatefulWidget {
  const ImageLabelingFromGallery({super.key});

  @override
  State<ImageLabelingFromGallery> createState() => _ImageLabelingFromGalleryState();
}

class _ImageLabelingFromGalleryState extends State<ImageLabelingFromGallery> {

  late ImageLabeler imageLabeler;
  final ImageController _machineController = ImageController.instance;
  File? imageUrl;
  String result = '';

  @override
  void initState() {
    ImageLabelerOptions options = ImageLabelerOptions(confidenceThreshold: 0.5);
    imageLabeler = ImageLabeler(options: options);
    super.initState();
  }

  Future<void> parseImage() async {
    if (imageUrl != null) {
      final InputImage inputImage = InputImage.fromFile(imageUrl!);
      final List<ImageLabel> lable = await imageLabeler.processImage(inputImage);
      for (ImageLabel data in lable) {
        final text = data.label;
        final index = data.index;
        final confidence = data.confidence;
        result += "$text -- ${confidence.toStringAsFixed(2)} -- $index\n";
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Image Labeling", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              Image.file(imageUrl!, height: MediaQuery.of(context).size.width / 1.2, width: double.infinity, fit: BoxFit.cover),
            const SizedBox(height: 10),
            if (result != null)
              Expanded(child: Text(result, style: const TextStyle(color: Colors.black))),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          imageUrl = null;
          final img = await _machineController.pickImage(ImageSource.gallery);
          if (img != null) {
            setState(() {
              imageUrl = img;
              parseImage();
            });
          }
        },
        child: const Icon(CupertinoIcons.photo),
      ),
    );
  }
}