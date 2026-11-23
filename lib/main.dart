import 'dart:io';
import 'package:android_ios_specific_platform/screens/android_image_editor.dart';
import 'package:android_ios_specific_platform/screens/ios_image_editor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Android Image Editor',
        home: AndroidImageEditor(),
      );
    }
    if (Platform.isIOS) {
      return const CupertinoApp(
        debugShowCheckedModeBanner: false,
        title: 'iOS Image Editor',
        theme: CupertinoThemeData(
          primaryColor: CupertinoColors.activeOrange ,
        ),
        home: IOSImageEditor(),
      );
    }
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Platform not supported'),
        ),
      ),
    );
  }
}
