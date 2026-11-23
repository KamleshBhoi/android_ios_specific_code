import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ImageEditorScreen extends StatefulWidget {
  const ImageEditorScreen({super.key});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  static const MethodChannel channel = MethodChannel(
    'com.example.image_editor/crop',
  );

  final ImagePicker picker = ImagePicker();

  File? selectedImage;
  bool isLoading = false;
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
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
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
  Future<void> saveEditedImage(Uint8List bytes) async {
    final file = File(
      '${Directory.systemTemp.path}/edited_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );

    await file.writeAsBytes(bytes, flush: true);

    if (mounted) {
      setState(() {
        selectedImage = file;
      });
    }
  }
  Future<void> cropImage() async {
    if (selectedImage == null || isLoading) return;

    setState(() => isLoading = true);

    try {
      final bytes = await selectedImage!.readAsBytes();

      final Uint8List? croppedBytes = await channel.invokeMethod<Uint8List>(
        'cropImage',
        {'imageBytes': bytes},
      );

      if (croppedBytes != null && mounted) {
        await saveEditedImage(croppedBytes);
      }
    } on PlatformException catch (e) {
      showMessage(e.message ?? 'Cropping failed');
    } catch (e) {
      showMessage('Crop error: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
  Future<void> flipImage(bool horizontal) async {
    if (selectedImage == null || isLoading) return;

    setState(() => isLoading = true);

    try {
      final bytes = await selectedImage!.readAsBytes();

      final Uint8List? output = await channel.invokeMethod<Uint8List>(
        'flipImage',
        {'imageBytes': bytes, 'horizontal': horizontal},
      );

      if (output != null && mounted) {
        await saveEditedImage(output);
      }
    } on PlatformException catch (e) {
      showMessage(e.message ?? 'Flip failed');
    } catch (e) {
      showMessage('Flip error: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
  Future<void> rotateImage() async {
    if (selectedImage == null || isLoading) return;

    setState(() => isLoading = true);

    try {
      final bytes = await selectedImage!.readAsBytes();

      final Uint8List? output = await channel.invokeMethod<Uint8List>(
        'rotateImage',
        {'imageBytes': bytes},
      );

      if (output != null && mounted) {
        await saveEditedImage(output);
      }
    } on PlatformException catch (e) {
      showMessage(e.message ?? 'Rotation failed');
    } catch (e) {
      showMessage('Rotation error: $e');
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
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,

      appBar: AppBar(
        title: const Text('Native Image Editor'),
        backgroundColor: Colors.orange,
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
                  border: Border.all(color: Colors.orange, width: 2),
                ),

                child: selectedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 80,
                            color: Colors.orange,
                          ),

                          SizedBox(height: 12),

                          Text(
                            'Tap to Select Image',
                            style: TextStyle(fontSize: 18),
                          ),

                          SizedBox(height: 5),

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
                  label: const Text('Crop Image'),
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => flipImage(true),
                  icon: const Icon(Icons.flip),
                  label: const Text('Flip Horizontal'),
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => flipImage(false),
                  icon: const Icon(Icons.flip),
                  label: const Text('Flip Vertical'),
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: rotateImage,
                  icon: const Icon(Icons.rotate_right),
                  label: const Text('Rotate 90°'),
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
