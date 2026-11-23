import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class ImageEditorService {
  static final ImagePicker _picker = ImagePicker();
  static Future<XFile?> pickFromGallery() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
  }
  static Future<XFile?> pickFromCamera() async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );
  }
  static Future<File?> cropImage(String imagePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: [
        if (Platform.isAndroid)
          AndroidUiSettings(
            toolbarTitle: 'Android Image Editor',
            toolbarColor: Colors.orange,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: Colors.orange,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
        if (Platform.isIOS)
          IOSUiSettings(
            title: 'iOS Image Editor',
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: false,
            aspectRatioLockEnabled: false,
          ),
      ],
    );
    if (croppedFile == null) return null;
    return File(croppedFile.path);
  }
  static Future<File> flipImage(
      File sourceFile, {
        required bool horizontal,
      }) async {
    final bytes = await sourceFile.readAsBytes();
    final decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) {
      throw Exception('Unable to decode image');
    }

    final flippedImage = img.flip(
      decodedImage,
      direction: horizontal
          ? img.FlipDirection.horizontal
          : img.FlipDirection.vertical,
    );
    final outputBytes = img.encodeJpg(
      flippedImage,
      quality: 95,
    );
    final directory = await getTemporaryDirectory();
    final outputFile = File(
      '${directory.path}/edited_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await outputFile.writeAsBytes(outputBytes);
    return outputFile;
  }
}
