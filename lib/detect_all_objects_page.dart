import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For immersive mode
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';  // Import for FlutterVision
import 'boundingbox.dart';
import 'object_heights.dart'; // Import the object heights mapping
import 'zoom_slider.dart';  // Import the new ZoomSlider widget
import 'flash_button.dart';  // Import FlashButton widget
import 'back_button_widget.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Import for Flutter TTS
import 'package:vibration/vibration.dart'; // Import for vibration functionality
import 'dart:async'; // Import for Timer

List<CameraDescription>? cameras;

class DetectAllObjectsPage extends StatefulWidget {
  const DetectAllObjectsPage({Key? key}) : super(key: key);

  @override
  _DetectAllObjectsPageState createState() => _DetectAllObjectsPageState();
}

class _DetectAllObjectsPageState extends State<DetectAllObjectsPage> {
  late FlutterVision vision;
  CameraController? controller;
  bool isDetecting = false;
  List<dynamic> detections = [];
  bool modelLoaded = false;
  String latency = "0 ms"; // Variable to hold latency value
  Color statusBarColor = Colors.black.withOpacity(0.6); // Default color for status bar
  double _currentZoomLevel = 1.0; // Initial zoom level
  double _maxZoomLevel = 1.0; // Max zoom level
  FlutterTts flutterTts = FlutterTts(); // Initialize Flutter TTS
  bool audioFeedbackActive = false; // Flag to manage audio feedback
  Timer? audioFeedbackTimer; // Timer for audio feedback reset

  @override
  void initState() {
    super.initState();
    initializeCameras();
    // Enable immersive mode to hide system UI (but keep custom status bar visible)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    if (controller != null && controller!.value.isInitialized) {
      controller!.dispose(); // Safely dispose of the controller
      controller = null; // Nullify to prevent future use
    }
    super.dispose(); // Always call super.dispose() at the end
  }

  // Initialize the cameras and load the model
  Future<void> initializeCameras() async {
    try {
      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        throw Exception('No cameras found');
      }

      controller = CameraController(
        cameras![0],
        ResolutionPreset.high, // Lower resolution for faster processing
      );

      await controller?.initialize();
      await loadYoloModel();

      // Get the max zoom level for the camera
      _maxZoomLevel = await controller!.getMaxZoomLevel();

      if (!mounted) return;

      controller?.startImageStream((CameraImage image) {
        if (!isDetecting && modelLoaded) {
          isDetecting = true;
          detectObjects(image); // Automatically detect objects when page loads
        }
      });

      setState(() {});
    } catch (e) {
      print('Error initializing cameras: $e');
    }
  }

  // Load the YOLOv8 model
  Future<void> loadYoloModel() async {
    vision = FlutterVision();
    await vision.loadYoloModel(
      labels: 'assets/coco_classes.txt',
      modelPath: 'assets/best_float16.tflite',
      modelVersion: 'yolov8',
      quantization: false,
      numThreads: 4,
      useGpu: true,
    );
    modelLoaded = true;
  }

  // Perform object detection on each frame
  Future<void> detectObjects(CameraImage image) async {
    final stopwatch = Stopwatch()..start();

    final result = await vision.yoloOnFrame(
      bytesList: image.planes.map((plane) => plane.bytes).toList(),
      imageHeight: image.height,
      imageWidth: image.width,
      iouThreshold: 0.5,
      confThreshold: 0.5,
      classThreshold: 0.5,
    );

    stopwatch.stop();

    setState(() {
      detections = result;

      latency = '${stopwatch.elapsed.inMilliseconds}'; // Only display the number of ms

      // Change status bar color to green when objects are detected
      if (detections.isNotEmpty) {
        statusBarColor = Colors.green;

        // Determine feedback message based on the number of detections
        String feedbackMessage = detections.length == 1
            ? 'Object detected'
            : 'Objects detected';

        // Trigger audio feedback if not already active
        if (!audioFeedbackActive) {
          _giveAudioFeedback(feedbackMessage);
          Vibration.vibrate(duration: 500); // Vibrate for 500 milliseconds
          audioFeedbackActive = true; // Set flag to prevent immediate re-trigger

          // Reset audio feedback after 5 seconds
          audioFeedbackTimer = Timer(const Duration(seconds: 5), () {
            audioFeedbackActive = false; // Reset flag after timer
          });
        }
      } else {
        statusBarColor = Colors.redAccent; // Change color to red when no objects are found
      }

      isDetecting = false;
    });
  }

  // Provide audio feedback
  Future<void> _giveAudioFeedback(String message) async {
    await flutterTts.speak(message); // Speak the message
  }

  // Set zoom level for the camera
  Future<void> _setZoomLevel(double zoom) async {
    if (controller != null) {
      try {
        await controller!.setZoomLevel(zoom);
      } catch (e) {
        print("Error setting zoom level: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Your camera initialization and preview logic
          if (controller == null || !controller!.value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller!.value.previewSize!.height,
                    height: controller!.value.previewSize!.width,
                    child: CameraPreview(controller!),
                  ),
                ),
              ),
              _buildBoundingBoxOverlay(),
              _buildStatusOverlay(),
              BackButtonWidget(), // Same back button widget

              // Zoom slider
              Positioned(
                bottom: 150,
                left: 20,
                right: 20,
                child: ZoomSlider(
                  currentZoomLevel: _currentZoomLevel,
                  maxZoomLevel: _maxZoomLevel,
                  onZoomChanged: (double newZoomLevel) {
                    setState(() {
                      _currentZoomLevel = newZoomLevel;
                    });
                    _setZoomLevel(newZoomLevel); // Apply the zoom level
                  },
                ),
              ),

              // Flash button added here
              Positioned(
                top: 20,
                right: 20,
                child: FlashButton(
                  controller: controller!,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBoundingBoxOverlay() {
    return CustomPaint(
      painter: BoundingBoxPainter(detections, controller!),
      child: Container(),
    );
  }

  // The _buildStatusOverlay method
  Widget _buildStatusOverlay() {
    return Positioned(
      bottom: 100, // Position it just above the microphone button (mic button removed)
      left: 20,
      right: 20,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
          decoration: BoxDecoration(
            color: statusBarColor, // Change color dynamically based on detections
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                detections.isNotEmpty
                    ? Icons.check_circle_outline // Show check icon when objects are detected
                    : Icons.warning, // Show warning icon when no objects are found
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                detections.isNotEmpty ? 'Objects detected' : 'No objects found',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
