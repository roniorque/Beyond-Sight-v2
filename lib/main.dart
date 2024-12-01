import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For immersive mode
import 'detector.dart';
import 'speech.dart';
import 'welcome_page.dart';
import 'home_page.dart';
import 'detect_all_objects_page.dart'; // Import the new page
import 'navigate_to_object.dart'; // Import the new navigate to object page
import 'help_page.dart'; // Import the HelpPage class

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beyond Sight',
      debugShowCheckedModeBanner: false, // Optional: Removes the debug banner
      initialRoute: '/', // Set the initial route to the welcome page
      routes: {
        '/': (context) => WelcomePageWrapper(),
        '/home': (context) => HomePageWrapper(),
        '/object_detection': (context) => ObjectDetectionWrapper(),
        '/detect_all_objects': (context) => DetectAllObjectsPageWrapper(), // Route for DetectAllObjectsPage
        '/navigate_to_object': (context) => NavigateToObjectPageWrapper(), // New route for NavigateToObjectPage
        '/help': (context) => HelpPageWrapper(), // New route for HelpPage
      },
    );
  }
}

// Utility function to set immersive mode
void setImmersiveMode() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

// Create a wrapper for each page that needs immersive mode

// Wrapper for the Welcome Page
class WelcomePageWrapper extends StatefulWidget {
  @override
  _WelcomePageWrapperState createState() => _WelcomePageWrapperState();
}

class _WelcomePageWrapperState extends State<WelcomePageWrapper> {
  @override
  void initState() {
    super.initState();
    // Apply immersive mode after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setImmersiveMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WelcomePage(); // Use your existing WelcomePage widget here
  }
}

// Wrapper for the Home Page
class HomePageWrapper extends StatefulWidget {
  @override
  _HomePageWrapperState createState() => _HomePageWrapperState();
}

class _HomePageWrapperState extends State<HomePageWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setImmersiveMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    return HomePage(); // Use your existing HomePage widget here
  }
}

// Wrapper for Object Detection Page
class ObjectDetectionWrapper extends StatefulWidget {
  @override
  _ObjectDetectionWrapperState createState() => _ObjectDetectionWrapperState();
}

class _ObjectDetectionWrapperState extends State<ObjectDetectionWrapper> {
  String _objectToFind = ''; // Store the object to find based on the speech command
  bool _isListening = false; // Track if the microphone is listening or not

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setImmersiveMode();
    });
  }

  // Update the object to find based on the recognized command
  void _updateObjectToFind(String object) {
    setState(() {
      _objectToFind = object;
    });
  }

  // Toggle the listening state (called when the microphone button is pressed)
  void _toggleListening(bool isListening) {
    setState(() {
      _isListening = isListening; // Update the isListening state
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Object detection screen, passing the object to find from speech and listening state
          ObjectDetectionScreen(
            objectToFind: _objectToFind,
            isListening: _isListening, // Pass the listening state here (this is required)
          ),
          // Centered Speech command button (Microphone Icon)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: SpeechCommand(
                onCommandRecognized: _updateObjectToFind, // Pass the callback to update the object
                onListeningStateChanged: _toggleListening, // Pass the callback to update listening state
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Wrapper for Detect All Objects Page
class DetectAllObjectsPageWrapper extends StatefulWidget {
  @override
  _DetectAllObjectsPageWrapperState createState() => _DetectAllObjectsPageWrapperState();
}

class _DetectAllObjectsPageWrapperState extends State<DetectAllObjectsPageWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setImmersiveMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DetectAllObjectsPage(); // Use your existing DetectAllObjectsPage widget here
  }
}

// Wrapper for Navigate to Object Page
class NavigateToObjectPageWrapper extends StatefulWidget {
  @override
  _NavigateToObjectPageWrapperState createState() => _NavigateToObjectPageWrapperState();
}

class _NavigateToObjectPageWrapperState extends State<NavigateToObjectPageWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setImmersiveMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    return NavigateToObjectScreen(); // Use your existing NavigateToObjectScreen widget here
  }
}

// Wrapper for Help Page
class HelpPageWrapper extends StatefulWidget {
  @override
  _HelpPageWrapperState createState() => _HelpPageWrapperState();
}

class _HelpPageWrapperState extends State<HelpPageWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setImmersiveMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    return HelpPage(); // Use your existing HelpPage widget here
  }
}
