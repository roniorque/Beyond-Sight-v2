import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // For blur effect
import 'boundingbox.dart';
import 'zoom_slider.dart';
import 'flash_button.dart';
import 'back_button_widget.dart';
import 'object_heights.dart'; // Import object heights mapping
import 'package:flutter_tts/flutter_tts.dart'; // Import for Text to Speech
import 'package:flutter_vision/flutter_vision.dart'; // FlutterVision import
import 'package:intl/intl.dart'; // Import the intl package
import 'package:vibration/vibration.dart';

List<CameraDescription>? cameras;

class NavigateToObjectScreen extends StatefulWidget {
  const NavigateToObjectScreen({super.key});

  @override
  _NavigateToObjectScreenState createState() => _NavigateToObjectScreenState();
}

class _NavigateToObjectScreenState extends State<NavigateToObjectScreen> {
  late FlutterVision vision;
  CameraController? controller;
  bool isDetecting = false;
  List<dynamic> detections = [];
  bool modelLoaded = false;
  String selectedObject = ''; // Track the selected object
  final FlutterTts flutterTts = FlutterTts(); // For voice feedback
  bool hasSpokenLookingFor = false; // Flag to avoid repeating "Looking for" message
  bool hasSpokenNavigating = false; // Flag to avoid repeating "Navigating to" message
  bool hasSpokenObstacleWarning = false; // Flag to avoid repeating obstacle warning
  bool _isSpeaking = false; // To track if TTS is speaking
  bool _obstacleDetected = false; // Tracks whether an obstacle is currently detected
  bool _obstacleAnnounced = false; // To prevent multiple obstacle announcements
  String distance = '0.0m'; // Calculated distance to object
  bool _hasSpokenObstacleAfterObject = false; // New flag to track obstacle announcement
  Set<String> _announcedObstacles = {};
  bool _stopDetection = false; // Flag to signal detection should stop


  List<String> objectClasses = []; // Store valid object classes
  Color statusBarColor = Colors.black.withOpacity(0.6); // Status bar color
  double _currentZoomLevel = 1.0; // Initial zoom level
  double _maxZoomLevel = 1.0; // Max zoom level

  @override
  @override
  void initState() {
    super.initState();
    initializeCameras();
    loadCocoClasses(); // Load object classes
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky); // Enable immersive mode

    // Set the status bar color to green during initialization
    setState(() {
      statusBarColor = Colors.green; // Change the status bar color to green
    });
  }


  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  // Load object classes from coco_classes.txt
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

  // Initialize the camera and load YOLO model
  Future<void> initializeCameras() async {
    try {
      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        throw Exception('No cameras found');
      }

      controller = CameraController(cameras![0], ResolutionPreset.high);
      await controller?.initialize();
      await loadYoloModel();

      // Get the max zoom level for the camera
      _maxZoomLevel = await controller!.getMaxZoomLevel();

      if (!mounted) return;

      controller?.startImageStream((CameraImage image) {
        if (!isDetecting && modelLoaded && selectedObject.isNotEmpty) {
          isDetecting = true;
          detectObjects(image);
        }
      });

      setState(() {});
    } catch (e) {
      print('Error initializing cameras: $e');
    }
  }

  // Load the YOLO model
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

  Future<void> detectObjects(CameraImage image) async {
    if (_stopDetection) {
      return; // Exit early if detection should be stopped
    }
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
      // Reset detections for this frame
      detections = [];

      if (selectedObject.isNotEmpty) {
        // Filter for selected object
        final objectDetections = result.where((detection) => detection['tag'] == selectedObject.toLowerCase()).toList();

        if (objectDetections.isNotEmpty) {
          hasSpokenLookingFor = false;

          // Calculate distance using the first detected object
          double calculatedDistance = calculateDistance(objectDetections[0], image.width, image.height);

          // Update distance display
          _updateObjectDistance(selectedObject, calculatedDistance);

          // Announce the selected object and its distance
          _announceObjectAndDistance(selectedObject, calculatedDistance);
          hasSpokenNavigating = true;
          hasSpokenObstacleWarning = false; // Reset obstacle warning flag

          // Add selected object detections to the list
          detections.addAll(objectDetections);
        } else {
          // Handle looking for the object
          if (!hasSpokenLookingFor) {
            _speak("Looking for $selectedObject");
            hasSpokenLookingFor = true;
            hasSpokenNavigating = false; // Reset navigating flag
          }
        }
      }

      // Handle obstacle detection (independent from selected object)
      final obstacleDetections = result.where((detection) => detection['tag'] != selectedObject.toLowerCase()).toList();

      if (obstacleDetections.isNotEmpty) {
        for (var obstacleDetection in obstacleDetections) {
          double calculatedObstacleDistance = calculateDistance(obstacleDetection, image.width, image.height);

          // Only process obstacle if it's within 70 cm
          if (calculatedObstacleDistance < 70.0) {
            String obstacleName = obstacleDetection['tag'];

            // Announce the obstacle if it hasn't been announced already or if it's a new obstacle
            if (!_announcedObstacles.contains(obstacleName)) {
              _announceObstacle(obstacleName, calculatedObstacleDistance);
              _announcedObstacles.add(obstacleName);  // Add to announced obstacles list
            } else {
              // Re-announce if it’s a different obstacle in the same detection session
              _announceObstacle(obstacleName, calculatedObstacleDistance);
            }

            // Add obstacle detection to the list (for bounding box drawing)
            detections.add(obstacleDetection);
          }
        }
      }

      // Remove obstacles from the announced list if they are no longer detected
      _announcedObstacles.removeWhere((obstacle) => !result.any((detection) => detection['tag'] == obstacle));

      // Flag to indicate detection is done
      isDetecting = false;
    });
  }



  void _announceObstacle(String obstacleName, double distance) async {
    if (!_isSpeaking && !_obstacleAnnounced) {
      if (distance < 70.0) { // Only announce if the obstacle is within 70 cm
        String formattedDistance = distance.toStringAsFixed(0); // Whole number
        _speak("Warning! Obstacle detected: $obstacleName is $formattedDistance centimeters away.");
        _obstacleAnnounced = true;
        statusBarColor = Colors.yellow; // Set status bar color to yellow

        // Vibrate when an obstacle is detected
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 500); // Vibrate for 500 milliseconds
        }

        // Keep obstacle status until the object is found, then reset the color to green
        setState(() {
          if (selectedObject.isNotEmpty && detections.any((detection) => detection['tag'] == selectedObject.toLowerCase())) {
            _obstacleAnnounced = false; // Reset obstacle announcement
            statusBarColor = Colors.green; // Object found, reset status bar color to green
          }
        });
      }
    }
  }

  // Method to speak messages (Text-to-Speech)
  Future<void> _speak(String message) async {
    _isSpeaking = true;
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(message);
    flutterTts.setCompletionHandler(() {
      _isSpeaking = false; // Mark speaking as finished
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

  // Update distance dynamically
  void _updateObjectDistance(String object, double distanceInCm) {
    if (!_obstacleDetected) {
      if (distanceInCm >= 100.0) {
        double distanceInMeters = distanceInCm / 100.0;
        distance = '${distanceInMeters.toStringAsFixed(2)} m';
      } else {
        distance = '${distanceInCm.toStringAsFixed(0)} cm';
      }

      // Update the status bar color
      setState(() {
        statusBarColor = Colors.green;
      });
    }
  }

// Announce the object and distance
  void _announceObjectAndDistance(String object, double distanceInCm) {
    // Ensure the system is not already speaking and reset obstacle if object is detected after obstacle
    if (!_isSpeaking) { // Check if not already speaking
      // Reset obstacle announcement if object is detected
      if (_obstacleAnnounced) {
        _obstacleAnnounced = false; // Reset obstacle announcement
        _hasSpokenObstacleAfterObject = true; // Mark that object was found after obstacle
      }

      // Set speaking flag to prevent interruptions during object announcement
      _isSpeaking = true;

      // Handle distance announcement
      if (distanceInCm >= 100.0) {
        double distanceInMeters = distanceInCm / 100.0;
        _speak('Found $object in ${distanceInMeters.toStringAsFixed(2)} meters');
      } else {
        _speak('Found $object in ${distanceInCm.toStringAsFixed(0)} centimeters');
      }

      // Completion handler to reset flags after speech
      flutterTts.setCompletionHandler(() {
        _isSpeaking = false; // Allow new announcements
        // No need to reset _hasSpokenObstacleAfterObject here, keep it true
      });
    }
  }


  // Set the camera zoom level
  Future<void> _setZoomLevel(double zoom) async {
    if (controller != null) {
      try {
        await controller!.setZoomLevel(zoom);
      } catch (e) {
        print("Error setting zoom level: $e");
      }
    }
  }

  void _showObjectSelectionDialog() {
    // Stop any ongoing detection processes
    setState(() {
      _stopDetection = true; // Signal the detection process to stop
      isDetecting = false;   // Indicate no detection is currently running
      detections.clear();    // Clear previous detections
      selectedObject = '';   // Clear the selected object
      hasSpokenLookingFor = false;
      hasSpokenNavigating = false;
      hasSpokenObstacleWarning = false;
    });

    String searchTerm = '';
    List<String> sortedObjectClasses = List.from(objectClasses)
      ..sort()
      ..removeWhere((object) => object.isEmpty); // Remove empty object at index 0

    // Stop the object detection when selecting a new object
    isDetecting = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal on tap outside
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white, // Light background
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0), // Rounded corners
                side: BorderSide(color: Colors.blueAccent, width: 2.0), // Blue accent border
              ),
              child: Container(
                height: double.infinity, // Full-screen height
                width: double.infinity, // Full-screen width
                padding: const EdgeInsets.all(20.0), // Add padding for overall layout
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select an Object',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 20), // Space between title and text field
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search Objects', // Hint text before user taps
                        hintStyle: TextStyle(color: Colors.black54), // Light hint color
                        prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                        filled: true,
                        fillColor: Colors.white, // Light blue fill color for the text field
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: Colors.blueAccent), // Blue border initially
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: Colors.black, width: 2.0), // Black border on focus
                        ),
                      ),
                      cursorColor: Colors.blueAccent, // Change cursor color to blue accent
                      style: TextStyle(color: Colors.black), // Text color
                      onChanged: (value) {
                        setState(() {
                          searchTerm = value.toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 10), // Space between text field and list
                    Expanded(
                      child: SingleChildScrollView(
                        child: ListBody(
                          children: [
                            ...sortedObjectClasses.where((object) {
                              return searchTerm.isEmpty || object.toLowerCase().contains(searchTerm);
                            }).map((object) {
                              String capitalizedObject = toBeginningOfSentenceCase(object) ?? object; // Capitalize the first letter
                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  setState(() {
                                    selectedObject = object;

                                    // Speak only if it hasn't been spoken before
                                    if (!hasSpokenLookingFor) {
                                      _speak('Looking for $capitalizedObject');
                                      hasSpokenLookingFor = true; // Set the flag to true after speaking
                                    }

                                    // Reset obstacle detection state
                                    _obstacleAnnounced = false; // Reset obstacle announcement
                                    _stopDetection = false; // Allow detection to resume
                                  });

                                  // Restart the detection process
                                  if (controller != null && modelLoaded) {
                                    controller!.startImageStream((CameraImage image) {
                                      if (!isDetecting && selectedObject.isNotEmpty) {
                                        isDetecting = true;
                                        detectObjects(image);
                                      }
                                    });
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 15.0), // Add padding for each list item
                                  decoration: BoxDecoration(
                                    color: Colors.white, // Change to white for the list items
                                    border: Border(bottom: BorderSide(color: Colors.black12)),
                                  ),
                                  child: Text(
                                    capitalizedObject,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                    // Cancel button at the bottom
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: TextButton(
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (controller == null || !controller!.value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              // Camera preview
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
              if (selectedObject.isEmpty)
              // Blur effect when no object is selected
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ),
                ),
              // Bounding box painter
              CustomPaint(
                painter: BoundingBoxPainter(
                  detections.where((detection) => detection['tag'] == selectedObject.toLowerCase()
                      || (detection['tag'] != selectedObject.toLowerCase() && _obstacleAnnounced)).toList(),
                  // Only paint obstacles when warning triggered
                  controller!,
                  selectedObject: selectedObject,
                ),
                child: Container(),
              ),
              // Status overlay for object detection results
              _buildStatusOverlay(),
              // Back button
              const BackButtonWidget(),
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
                    _setZoomLevel(newZoomLevel); // Apply zoom level change
                  },
                ),
              ),
              // Flash button
              Positioned(
                top: 20,
                right: 20,
                child: FlashButton(
                  controller: controller!,
                ),
              ),
              // Object selection button at the bottom
              Positioned(
                bottom: 40, // Adjusted position to move 10px upwards
                left: 20,
                right: 20,
                child: ElevatedButton(
                  onPressed: _showObjectSelectionDialog, // Show the object selection dialog
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, // Accent blue color for button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded edges for modern look
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15), // Add padding for button height
                  ),
                  child: const Text(
                    'Select Object',
                    style: TextStyle(color: Colors.white, fontSize: 20), // Text color and font size
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Status overlay widget
  Widget _buildStatusOverlay() {
    return Positioned(
      bottom: 110,
      left: 20,
      right: 20,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
          decoration: BoxDecoration(
            color: statusBarColor, // Dynamic color based on detection
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _obstacleAnnounced
                    ? Icons.warning
                    : (detections.isNotEmpty && selectedObject.isNotEmpty
                    ? Icons.info_outline
                    : Icons.info_outline), // Icon based on detection result
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                selectedObject.isNotEmpty
                    ? detections.isNotEmpty && !_obstacleAnnounced
                    ? '$selectedObject detected: $distance' // Object found
                    : _obstacleAnnounced
                    ? 'Obstacle' // Obstacle detected
                    : 'Looking for $selectedObject' // Searching for object
                    : '', // No object selected
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
