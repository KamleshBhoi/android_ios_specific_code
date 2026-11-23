// import 'dart:io';
// import 'package:flutter/cupertino.dart';
// import '../services/image_editor_services.dart';
//
// class IOSImageEditor extends StatefulWidget {
//   const IOSImageEditor({super.key});
//
//   @override
//   State<IOSImageEditor> createState() => _IOSImageEditorState();
// }
//
// class _IOSImageEditorState extends State<IOSImageEditor> {
//   File? selectedImage;
//   bool isLoading = false;
//
//   Future<void> selectImage() async {
//     final source = await showCupertinoModalPopup<String>(
//       context: context,
//       builder: (context) {
//         return CupertinoActionSheet(
//           title: const Text('Select Image'),
//           actions: [
//             CupertinoActionSheetAction(
//               onPressed: () =>
//                   Navigator.pop(context, 'gallery'),
//               child: const Text('Choose from Gallery'),
//             ),
//             CupertinoActionSheetAction(
//               onPressed: () =>
//                   Navigator.pop(context, 'camera'),
//               child: const Text('Take Photo'),
//             ),
//           ],
//           cancelButton: CupertinoActionSheetAction(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
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
//
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
//
//   Future<void> cropImage() async {
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
//     showCupertinoDialog(
//       context: context,
//       builder: (context) {
//         return CupertinoAlertDialog(
//           title: const Text('Image Editor'),
//           content: Text(message),
//           actions: [
//             CupertinoDialogAction(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//   @override
//   Widget build(BuildContext context) {
//     return CupertinoPageScaffold(
//       navigationBar: const CupertinoNavigationBar(
//         middle: Text('iOS Image Editor'),
//       ),
//       child: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             children: [
//               GestureDetector(
//                 onTap: isLoading ? null : selectImage,
//                 child: Container(
//                   width: double.infinity,
//                   height: 300,
//                   decoration: BoxDecoration(
//                     color: CupertinoColors.activeOrange,
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(
//                       color: CupertinoColors.activeGreen,
//                       width: 2,
//                     ),
//                   ),
//                   child: selectedImage == null
//                       ? const Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         CupertinoIcons.photo,
//                         size: 80,
//                         color: CupertinoColors.systemGreen,
//                       ),
//                       SizedBox(height: 12),
//                       Text(
//                         'Tap to Select Image',
//                         style: TextStyle(fontSize: 18),
//                       ),
//                       SizedBox(height: 5),
//                       Text('Choose From Gallery or Camera'),
//                     ],
//                   )
//                       : ClipRRect(
//                     borderRadius: BorderRadius.circular(16),
//                     child: Image.file(
//                       selectedImage!,
//                       fit: BoxFit.contain,
//                       width: double.infinity,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 25),
//               if (isLoading)
//                 const CupertinoActivityIndicator(radius: 16)
//               else if (selectedImage != null) ...[
//                 SizedBox(
//                   width: double.infinity,
//                   child: CupertinoButton.filled(
//                     onPressed: cropImage,
//                     child: const Text('Crop / Rotate Image'),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: CupertinoButton(
//                         color: CupertinoColors.systemGrey5,
//                         onPressed: () => flipImage(true),
//                         child: const Text(
//                           'Flip Horizontal',
//                           style: TextStyle(
//                             color: CupertinoColors.activeBlue,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: CupertinoButton(
//                         color: CupertinoColors.systemGrey5,
//                         onPressed: () => flipImage(false),
//                         child: const Text(
//                           'Flip Vertical',
//                           style: TextStyle(
//                             color: CupertinoColors.activeBlue,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 CupertinoButton(
//                   onPressed: resetImage,
//                   child: const Text('Remove Image'),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
