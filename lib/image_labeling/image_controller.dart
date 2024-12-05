import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImageController {

  ImageController.__();
  static ImageController instance = ImageController.__();
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    return image != null ? File(image.path) : null;
  }
}