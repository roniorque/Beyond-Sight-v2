import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'boundingbox.dart';
import 'object_heights.dart'; // Import the object heights mapping

List<CameraDescription>? cameras;

class ObjectDetectionScreen extends StatefulWidget {
  final String objectToFind; // Pass the object to find from speech

  const ObjectDetectionScreen({super.key, required this.objectToFind});

  @override
  _ObjectDetectionScreenState createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  late FlutterVision vision;
  CameraController? controller;
  bool isDetecting = false;
  List<dynamic> detections = [];
  bool modelLoaded = false;
  String latency = "0 ms"; // Variable to hold latency value
  bool _objectAnnounced = false; // To prevent multiple announcements of found object
  bool _objectNotFoundAnnounced = false; // To prevent multiple announcements of "Object not found"
  final FlutterTts flutterTts = FlutterTts(); // Text-to-Speech instance
  List<String> objectClasses = []; // Store valid object classes

  @override
  void initState() {
    super.initState();
    initializeCameras();
    loadCocoClasses(); // Load object classes
  }

  // Load the object classes from coco_classes.txt
  Future<void> loadCocoClasses() async {
    try {
      String data = await DefaultAssetBundle.of(context).loadString('assets/coco_classes.txt');
      setState(() {
        objectClasses = data.split('\n').map((e) => e.trim()).toList();
      });
    } catch (e) {
      print('Error loading classes: $e');
    }
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

      if (!mounted) return;

      controller?.startImageStream((CameraImage image) {
        if (!isDetecting && modelLoaded) {
          isDetecting = true;
          detectObjects(image);
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

    // Check if the object to find exists in the list of COCO objects before detection
    if (!objectClasses.contains(widget.objectToFind.toLowerCase())) {
      // Announce "Object not found" only once
      if (!_objectNotFoundAnnounced) {
        _speak('Object ${widget.objectToFind} not found in detection list');
        _objectNotFoundAnnounced = true; // Mark "Object not found" as announced
      }
      setState(() {
        isDetecting = false; // Skip detection for this frame
      });
      return;
    }

    // Proceed with detection if the object is in the list
    final result = await vision.yoloOnFrame(
      bytesList: image.planes.map((plane) => plane.bytes).toList(),
      imageHeight: image.height,
      imageWidth: image.width,
      iouThreshold: 0.4,
      confThreshold: 0.2,
      classThreshold: 0.2,
    );

    stopwatch.stop();

    setState(() {
      // Filter detections based on speech command
      detections = result.where((detection) {
        return detection['tag'] == widget.objectToFind.toLowerCase();
      }).toList();

      if (detections.isNotEmpty && !_objectAnnounced) {
        double distance = calculateDistance(detections[0], image.width, image.height); // Calculate distance
        _announceObjectAndDistance(widget.objectToFind, distance); // Announce object and distance
        _objectAnnounced = true; // Mark object as announced
        _objectNotFoundAnnounced = false; // Reset the "Object not found" flag
      } else if (detections.isEmpty) {
        // Reset the announcement flag if no object is detected
        _objectAnnounced = false;
      }

      latency = '${stopwatch.elapsed.inMilliseconds} ms';
    });

    isDetecting = false;
  }

  // New method: Get object height from the object_heights.dart file
  double getObjectHeight(String objectTag) {
    return objectHeights[objectTag] ?? 20.0; // Default to 20 cm if object height is not found
  }

  // Calculate distance based on bounding box size and known object size
  double calculateDistance(dynamic detection, int imageWidth, int imageHeight) {
    final box = detection['box']; // Assuming the box contains [left, top, right, bottom]
    double objectHeightInImage = (box[3] - box[1]).abs();

    double knownObjectHeight = getObjectHeight(detection['tag']); // Get object height from mapping
    double focalLength = 400.0; // Use 400 as focal length

    double distanceInCm = (knownObjectHeight * focalLength) / objectHeightInImage;
    return distanceInCm;
  }

  // Announce the object and distance based on the magnitude of distance
  void _announceObjectAndDistance(String object, double distanceInCm) {
    if (distanceInCm >= 100.0) {
      double distanceInMeters = distanceInCm / 100.0;
      _speak('Found $object in ${distanceInMeters.toStringAsFixed(2)} meters');
    } else {
      _speak('Found $object in ${distanceInCm.toStringAsFixed(0)} centimeters');
    }
  }

  // TTS function to speak the detected object and distance
  Future<void> _speak(String message) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(message);
  }

  @override
  void dispose() {
    controller?.dispose();
    vision.closeYoloModel();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
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
          ],
        );
      },
    );
  }

  Widget _buildBoundingBoxOverlay() {
    return CustomPaint(
      painter: BoundingBoxPainter(detections, controller!, latency),
      child: Container(),
    );
  }
}
