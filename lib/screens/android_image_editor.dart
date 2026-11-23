// import 'dart:io';
// import 'package:flutter/material.dart';
//
// class AndroidImageEditor extends StatefulWidget {
//   const AndroidImageEditor({super.key});
//
//   @override
//   State<AndroidImageEditor> createState() => _AndroidImageEditorState();
// }
//
// class _AndroidImageEditorState extends State<AndroidImageEditor> {
//   File? selectedImage;
//   bool isLoading = false;
//
//   Future<void> selectImage() async {
//     final source = await showModalBottomSheet<String>(
//       context: context,
//       builder: (context) {
//         return SafeArea(
//           child: Wrap(
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.photo_library),
//                 title: const Text('Choose from Gallery'),
//                 onTap: () =>
//                     Navigator.pop(context, 'gallery'),
//               ),
//               ListTile(
//                 leading: const Icon(Icons.camera_alt),
//                 title: const Text('Take Photo'),
//                 onTap: () =>
//                     Navigator.pop(context, 'camera'),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//     if (source == null) return;
//     setState(() => isLoading = true);
//     try {
//       final image = source == 'gallery'
//           ? await ImageEditorService.pickFromGallery()
//           : await ImageEditorService.pickFromCamera();
//       if (image != null && mounted) {
//         setState(() {
//           selectedImage = File(image.path);
//         });
//       }
//     } catch (e) {
//       showMessage('Image selection failed: $e');
//     } finally {
//       if (mounted) {
//         setState(() => isLoading = false);
//       }
//     }
//   }
//   Future<void>cropImage() async {
//     if (selectedImage == null) return;
//     setState(() => isLoading = true);
//     try {
//       final cropped = await ImageEditorService.cropImage(
//         selectedImage!.path,
//       );
//       if (cropped != null && mounted) {
//         setState(() {
//           selectedImage = cropped;
//         });
//       }
//     } catch (e) {
//       showMessage('Crop failed: $e');
//     } finally {
//       if (mounted) {
//         setState(() => isLoading = false);
//       }
//     }
//   }
//   Future<void> flipImage(bool horizontal) async {
//     if (selectedImage == null) return;
//     setState(() => isLoading = true);
//     try {
//       final flipped = await ImageEditorService.flipImage(
//         selectedImage!,
//         horizontal: horizontal,
//       );
//       if (mounted) {
//         setState(() {
//           selectedImage = flipped;
//         });
//       }
//     } catch (e) {
//       showMessage('Flip failed: $e');
//     } finally {
//       if (mounted) {
//         setState(() => isLoading = false);
//       }
//     }
//   }
//   void resetImage() {
//     setState(() {
//       selectedImage = null;
//     });
//   }
//   void showMessage(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.green.shade100,
//       appBar: AppBar(
//         title: const Text('Android Image Editor'),
//         backgroundColor: Colors.green.shade500,
//         foregroundColor: Colors.black,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             GestureDetector(
//               onTap: isLoading ? null : selectImage,
//               child: Container(
//                 width: double.infinity,
//                 height: 300,
//                 decoration: BoxDecoration(
//                   color: Colors.orange.shade50,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(
//                     color: Colors.orange.shade200,
//                     width: 2,
//                   ),
//                 ),
//                 child: selectedImage == null
//                     ? const Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.add_photo_alternate,
//                       size: 80,
//                       color: Colors.green,
//                     ),
//                     SizedBox(height: 12),
//                     Text(
//                       'Tap to Select Image',
//                       style: TextStyle(fontSize: 18),
//                     ),
//                     SizedBox(height: 5),
//                     Text('Choose From Gallery or Camera'),
//                   ],
//                 )
//                     : ClipRRect(
//                   borderRadius: BorderRadius.circular(16),
//                   child: Image.file(
//                     selectedImage!,
//                     fit: BoxFit.contain,
//                     width: double.infinity,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 25),
//             if (isLoading)
//               const CircularProgressIndicator()
//             else if (selectedImage != null) ...[
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   onPressed: cropImage,
//                   icon: const Icon(Icons.crop),
//                   label: const Text('Crop / Rotate Image'),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: () => flipImage(true),
//                       icon: const Icon(Icons.flip),
//                       label: const Text('Flip Horizontal'),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: () => flipImage(false),
//                       icon: const Icon(Icons.flip),
//                       label: const Text('Flip Vertical'),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               TextButton.icon(
//                 onPressed: resetImage,
//                 icon: const Icon(Icons.refresh),
//                 label: const Text('Remove Image'),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
