import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:truler/controller.dart';

class Home extends StatelessWidget{
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<ObjectController>(
        init: ObjectController(),
        builder: (controller) {
          if (controller.isCameraInitialized.value) {
            return Stack(
              children: [
                CameraPreview(controller.cameraController),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Text(
                      controller.labelText.value.toUpperCase(),
                      style: const TextStyle(color: Colors.lightGreenAccent, fontWeight: FontWeight.w600)),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}