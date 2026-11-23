import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ImageEditorScreen extends StatefulWidget {
  const ImageEditorScreen({super.key});

  @override
  State<ImageEditorScreen> createState() =>
      _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {

  static const MethodChannel channel =
  MethodChannel('com.example.image_editor/crop');

  final ImagePicker picker = ImagePicker();

  File? selectedImage;
  bool isLoading = false;

  // IMAGE PICKER USING DART PACKAGE
  Future<void> selectImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(
                  context,
                  ImageSource.gallery,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(
                  context,
                  ImageSource.camera,
                ),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    setState(() => isLoading = true);

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (image != null && mounted) {
        setState(() {
          selectedImage = File(image.path);
        });
      }
    } catch (e) {
      showMessage('Image selection failed: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // NATIVE IMAGE CROPPING
  Future<void> cropImage() async {
    if (selectedImage == null) return;

    setState(() => isLoading = true);

    try {
      final bytes = await selectedImage!.readAsBytes();

      final Uint8List? croppedBytes =
      await channel.invokeMethod<Uint8List>(
        'cropImage',
        {'imageBytes': bytes},
      );

      if (croppedBytes != null && mounted) {
        final directory = await Directory.systemTemp.createTemp(
          'native_crop_',
        );

        final croppedFile = File(
          '${directory.path}/cropped_image.jpg',
        );

        await croppedFile.writeAsBytes(croppedBytes);

        if (mounted) {
          setState(() {
            selectedImage = croppedFile;
          });
        }
      }
    } on PlatformException catch (e) {
      showMessage(e.message ?? 'Cropping failed');
    } catch (e) {
      showMessage('Cropping failed: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void resetImage() {
    setState(() {
      selectedImage = null;
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Native Image Editor'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: isLoading ? null : selectImage,
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blue,
                    width: 2,
                  ),
                ),
                child: selectedImage == null
                    ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 80,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Tap to Select Image',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text('Gallery or Camera'),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    selectedImage!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            if (isLoading)
              const CircularProgressIndicator()
            else if (selectedImage != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: cropImage,
                  icon: const Icon(Icons.crop),
                  label: const Text('Native Crop Image'),
                ),
              ),

              const SizedBox(height: 12),

              TextButton.icon(
                onPressed: resetImage,
                icon: const Icon(Icons.refresh),
                label: const Text('Remove Image'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
