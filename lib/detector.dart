import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For immersive mode
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';  // Import for Text-to-Speech
import 'package:flutter_vision/flutter_vision.dart';  // Import for FlutterVision
import 'boundingbox.dart';
import 'object_heights.dart'; // Import the object heights mapping
import 'zoom_slider.dart';  // Import the new ZoomSlider widget
import 'flash_button.dart';  // Import FlashButton widget
import 'back_button_widget.dart';

List<CameraDescription>? cameras;

class ObjectDetectionScreen extends StatefulWidget {
  final String objectToFind; // Pass the object to find from speech
  final bool isListening;    // Required to know if the mic is on or off

  const ObjectDetectionScreen({
    super.key,
    required this.objectToFind,
    required this.isListening, // Ensure this is passed as required
  });

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
  bool _objectAnnounced = false; // To prevent multiple announcements of the same object
  bool _objectNotFoundAnnounced = false; // To prevent multiple announcements of "Object not found"
  bool _isSpeaking = false; // To track if the TTS is speaking
  final FlutterTts flutterTts = FlutterTts(); // Text-to-Speech instance
  List<String> objectClasses = []; // Store valid object classes
  String detectedObjectMessage = 'Not listening'; // Default message when mic is off
  Color statusBarColor = Colors.black.withOpacity(0.6); // Default color for status bar
  double _currentZoomLevel = 1.0; // Initial zoom level
  double _maxZoomLevel = 1.0; // Max zoom level
  bool _findingSpoken = false; // To track if the finding message has been spoken
  bool _findingMessageSpoken = false; // To track if the finding message has been spoken


  @override
  void initState() {
    super.initState();
    initializeCameras();
    loadCocoClasses(); // Load object classes

    // Enable immersive mode to hide system UI (but keep custom status bar visible)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // If the controller is still active, stop it and dispose it
    if (controller != null && controller!.value.isInitialized) {
      controller!.dispose(); // Safely dispose of the controller
      controller = null; // Nullify to prevent future use
    }

    super.dispose(); // Always call super.dispose() at the end
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

      // Get the max zoom level for the camera
      _maxZoomLevel = await controller!.getMaxZoomLevel();

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
    final stopwatch = Stopwatch()
      ..start();

    // Check if the object to find exists in the list of COCO objects before detection
    if (!objectClasses.contains(widget.objectToFind.toLowerCase())) {
      // Announce "Object not found" only once
      if (!_objectNotFoundAnnounced) {
        _speak('Object ${widget.objectToFind} not found in detection list');
        _objectNotFoundAnnounced = true; // Mark "Object not found" as announced
      }

      // Update status bar message to "Try other objects"
      setState(() {
        detectedObjectMessage = "Try other objects"; // New status message
        statusBarColor = Colors
            .redAccent; // Change the status bar color to red when not found
        isDetecting = false; // Skip detection for this frame
      });

      return;
    }

    // Proceed with detection if the object is in the list
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
      // Filter detections based on speech command
      detections = result.where((detection) {
        return detection['tag'] == widget.objectToFind.toLowerCase();
      }).toList();

      if (widget.isListening) {
        if (detections.isNotEmpty) {
          double distance = calculateDistance(
              detections[0], image.width, image.height); // Calculate distance

          // Get the height of the detected object
          double objectHeight = objectHeights[detections[0]['tag']] ??
              0.0; // Default to 0 if not found

          // Update the object distance dynamically
          _updateObjectDistance(widget.objectToFind, distance);

          if (!_objectAnnounced) {
            _announceObjectAndDistance(widget.objectToFind, distance);
            _objectAnnounced = true; // Mark object as announced
            _objectNotFoundAnnounced =
            false; // Reset the "Object not found" flag
          }
        } else if (detections.isEmpty && widget.objectToFind.isNotEmpty) {
          // If the object is being searched but not found
          if (!_findingMessageSpoken) { // Check if the finding message has been spoken
            _speak('Finding ${widget
                .objectToFind}...'); // Speak the finding message
            _findingMessageSpoken =
            true; // Mark that the finding message has been spoken
          }

          detectedObjectMessage = 'Finding ${widget.objectToFind}...';
          _objectAnnounced = false;
          statusBarColor = Colors.black.withOpacity(0.6); // Neutral color
        } else if (widget.objectToFind.isEmpty) {
          // If the mic is on but no object has been spoken yet
          detectedObjectMessage =
          'Listening'; // Show "Listening" when no object has been uttered
          statusBarColor = Colors.black.withOpacity(0.6); // Neutral color
          _findingMessageSpoken =
          false; // Reset finding message spoken flag when listening without a command
        }
      } else {
        // If mic is off, set to "Not listening"
        detectedObjectMessage = 'Not listening';
        statusBarColor = Colors.black.withOpacity(0.6);
        _findingMessageSpoken = false; // Reset flag when not listening
        _objectNotFoundAnnounced = false;
      }

      latency =
      '${stopwatch.elapsed.inMilliseconds}'; // Only display the number of ms
    });

    isDetecting = false;
  }


    // Method to speak messages (Text-to-Speech)
  Future<void> _speak(String message) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(message);
    flutterTts.setCompletionHandler(() {
      _isSpeaking = false; // Mark speaking as finished
      _objectAnnounced = false; // Reset object announcement after speaking
    });
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

  // Get object height from the object_heights.dart file
  double getObjectHeight(String objectTag) {
    return objectHeights[objectTag] ?? 20.0; // Default to 20 cm if object height is not found
  }

  // Update distance dynamically without repeating the announcement
  void _updateObjectDistance(String object, double distanceInCm) {
    if (distanceInCm >= 100.0) {
      double distanceInMeters = distanceInCm / 100.0;
      detectedObjectMessage = '$object: ${distanceInMeters.toStringAsFixed(2)} meters';
    } else {
      detectedObjectMessage = '$object: ${distanceInCm.toStringAsFixed(0)} cm'; // Change to "cm"
    }

    // Update the status bar color
    setState(() {
      statusBarColor = Colors.green;
    });
  }

  // Announce the object and distance based on the magnitude of distance
  void _announceObjectAndDistance(String object, double distanceInCm) {
    if (!_isSpeaking) {
      _isSpeaking = true; // Mark as speaking

      if (distanceInCm >= 100.0) {
        double distanceInMeters = distanceInCm / 100.0;
        _speak('Found $object in ${distanceInMeters.toStringAsFixed(2)} meters');
      } else {
        _speak('Found $object in ${distanceInCm.toStringAsFixed(0)} cm'); // Change to "cm"
      }
    }
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
            _buildStatusOverlay(),
            BackButtonWidget(),

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
              top: 20, // Adjusted to 20
              right: 20,
              child: FlashButton(
                controller: controller!,
              ),
            ),
          ],
        );
      },
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
      bottom: 100, // Position it just above the microphone button
      left: 20,
      right: 20,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
          decoration: BoxDecoration(
            color: statusBarColor, // Color based on detection status
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusBarColor == Colors.green
                    ? Icons.check_circle_outline // Show check icon when object is found
                    : (widget.isListening ? Icons.mic : Icons.mic_off), // Show mic or mic_off based on listening state
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                detectedObjectMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
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
