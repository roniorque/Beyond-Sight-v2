import 'package:flutter/material.dart';
import 'detector.dart'; // Assuming detector.dart is updated
import 'speech.dart';  // Assuming speech.dart has the logic to handle the mic

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _objectToFind = ''; // Store the object to find based on the speech command

  // Update the object to find based on the recognized command
  void _updateObjectToFind(String object) {
    setState(() {
      _objectToFind = object;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Object Detection with Voice Command'),
        ),
        body: Stack(
          children: [
            // Object detection screen, passing the object to find from speech
            ObjectDetectionScreen(
              objectToFind: _objectToFind,
            ),
            // Speech command button
            Positioned(
              bottom: 30,
              right: 30,
              child: SpeechCommand(
                onCommandRecognized: _updateObjectToFind, // Update the object to find
              ),
            ),
          ],
        ),
      ),
    );
  }
}
