import 'package:flutter/material.dart';
import 'home_page.dart';
class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Help',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.blueAccent,
            ),
          ),
          backgroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.blueAccent,
            indicatorWeight: 4.0,
            labelStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
            labelColor: Colors.blueAccent,
            tabs: [
              Tab(text: 'General'),
              Tab(text: 'Object Search'),
              Tab(text: 'All-Object Detection'),
              Tab(text: 'Object Guidance'),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
            onPressed: () {
              // Handle back navigation with a custom transition
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return HomePage(); // Ensure this is not const
                  },
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const beginScale = 1.0;
                    const endScale = 1.0; // Slightly zoom in
                    const curve = Curves.easeInOut; // Smooth curve for a modern feel

                    // Scale transition
                    var scaleTween = Tween<double>(begin: beginScale, end: endScale).chain(CurveTween(curve: curve));
                    var scaleAnimation = animation.drive(scaleTween);

                    // Fade transition
                    var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    ));

                    return ScaleTransition(
                      scale: scaleAnimation, // Apply scaling transition
                      child: FadeTransition(
                        opacity: fadeAnimation, // Apply fading transition
                        child: Container( // Ensure it fills the screen
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          child: child,
                        ),
                      ),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 800), // Adjust as necessary
                ),
              );
            },
          ),
        ),
        body: const TabBarView(
          children: [
            GeneralHelpTab(),
            FindObjectsHelpTab(),
            DetectAllObjectsHelpTab(),
            NavigateObjectHelpTab(),
          ],
        ),
      ),
    );
  }
}

class GeneralHelpTab extends StatelessWidget {
  const GeneralHelpTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white, // Clean white background
      child: ListView(
        children: [
          HelpCard(
            title: 'Welcome to Beyond Sight!',
            description:
            'This app utilizes advanced detection technology to assist in detecting and navigating objects. By employing deep learning models, specifically YOLOv8 and MobileNetV3 as the backbone, the app offers features such as Object Search, All-Object Detection, and Object Guidance.',
          ),
          const SizedBox(height: 16),
          HelpCard(
            title: 'Classes Detected',
            description:
            'This app detects several objects, including: \n'
                '1. Airplane\n'
                '2. Apple\n'
                '3. Backpack\n'
                '4. Banana\n'
                '5. Baseball Bat\n'
                '6. Baseball Glove\n'
                '7. Bed\n'
                '8. Bench\n'
                '9. Bird\n'
                '10. Boat\n'
                '11. Bottle\n'
                '12. Bowl\n'
                '13. Broccoli\n'
                '14. Cake\n'
                '15. Car\n'
                '16. Carrot\n'
                '17. Chair\n'
                '18. Cell Phone\n'
                '19. Clock\n'
                '20. Couch\n'
                '21. Cup\n'
                '22. Dining Table\n'
                '23. Dog\n'
                '24. Donut\n'
                '25. Elephant\n'
                '26. Fire Hydrant\n'
                '27. Frisbee\n'
                '28. Giraffe\n'
                '29. Hair Drier\n'
                '30. Handbag\n'
                '31. Horse\n'
                '32. Hot Dog\n'
                '33. Keyboard\n'
                '34. Knife\n'
                '35. Kite\n'
                '36. Laptop\n'
                '37. Microwave\n'
                '38. Motorcycle\n'
                '39. Mouse\n'
                '40. Oven\n'
                '41. Orange\n'
                '42. Parking Meter\n'
                '43. Pizza\n'
                '44. Potted Plant\n'
                '45. Refrigerator\n'
                '46. Remote\n'
                '47. Scissors\n'
                '48. Sheep\n'
                '49. Sink\n'
                '50. Skateboard\n'
                '51. Skis\n'
                '52. Snowboard\n'
                '53. Sports Ball\n'
                '54. Spoon\n'
                '55. Surfboard\n'
                '56. Teddy Bear\n'
                '57. Tennis Racket\n'
                '58. Tie\n'
                '59. Toaster\n'
                '60. Toilet\n'
                '61. Toothbrush\n'
                '62. Train\n'
                '63. Truck\n'
                '64. TV\n'
                '65. Umbrella\n'
                '66. Vase\n'
                '67. Wine Glass\n'
                '68. Zebra\n'
                '69. Bicycle\n'
                '70. Bus\n'
                '71. Cat\n'
                '72. Cow\n'
                '73. Dog\n'
                '74. Horse\n'
                '75. Motorcycle\n'
                '76. Person\n'
                '77. Sheep\n'
                '78. Stop Sign\n'
                '79. Traffic Light\n'
                '80. Train\n\n',
          ),
        ],
      ),
    );
  }
}

class HelpCard extends StatelessWidget {
  final String title;
  final String description;

  const HelpCard({Key? key, required this.title, required this.description}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blueAccent.withOpacity(0.7), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FindObjectsHelpTab extends StatelessWidget {
  const FindObjectsHelpTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _helpTab(
      title: 'Object Search',
      description:
      'The Object Search feature allows you to find specific objects using voice commands. Follow these steps to ensure you can use this feature effectively:\n\n'
          'Steps to Use Object Search:\n'
          '1. Tap the "Object Search" Button:\n'
          '   - This will activate the voice recognition feature.\n\n'
          '2. Speak Clearly and Specify the Object:\n'
          '   - Use your voice to specify the object you want to find. For example, say "Find banana" or "Find chair." \n'
          '   - Ensure you use the correct name of the object from our detection list (e.g., "car," "dog," "bottle").\n\n'
          '3. Listen for Feedback:\n'
          '   - The app will provide audio feedback indicating whether it has detected the object and its distance from you.\n'
          '   - If the object is not found, you will hear a message indicating that the object is not in the detection list, followed by suggestions to try other objects.\n\n'
          '4. Monitor the Status Bar:\n'
          '   - The status bar will display messages about the detection status and the distance to the found object. For example:\n'
          '     - "Found banana in 2.5 meters" if detected.\n'
          '     - "Finding banana..." if the search is ongoing.\n'
          '     - "Object not found. Try other objects." if the specified object cannot be detected.\n\n'
          'Tips for Best Results:\n'
          '- Quiet Environment: For optimal voice recognition, ensure you are in a quiet environment.\n'
          '- Stay Still: Avoid moving too much while speaking, as this can help the app focus better on your voice command.\n'
          '- Check Object List: Familiarize yourself with the list of objects the app can detect. Some examples include:\n'
          '  - Airplane\n'
          '  - Backpack\n'
          '  - Dog\n'
          '  - Bottle\n\n'
          'Additional Features:\n'
          '- Zoom Feature: Adjust the camera zoom level using the zoom slider to get a better view of the area.\n'
          '- Flashlight Option: Use the Flash button to illuminate dark areas when searching for objects.\n'
          '- Voice Feedback: The app uses text-to-speech to communicate with you, making it easier to follow along without needing to look at the screen.\n\n'
          'Troubleshooting:\n'
          '- If the app is not detecting the object correctly, check to ensure the camera is properly positioned and that there are no obstructions.\n'
          '- Restart the app if you encounter any issues with voice recognition.\n\n'
          'With these guidelines, you should be well-equipped to utilize the Object Search functionality effectively!',
    );
  }
}

class DetectAllObjectsHelpTab extends StatelessWidget {
  const DetectAllObjectsHelpTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _helpTab(
      title: 'All-Object Detection',
      description:
      'Identify all visible objects around you at once.\n\nSteps:\n'
          '1. Tap "All-Object Detection".\n'
          '2. The app scans and displays all detected objects in real-time.\n\n'
          'Overview:\n'
          'The All-Object Detection feature allows you to identify all visible objects around you simultaneously. This real-time scanning functionality uses advanced machine learning to recognize and display detected objects directly through your device\'s camera.\n\n'
          'Steps to Use All-Object Detection:\n'
          '1. Accessing the Feature:\n'
          '   - Tap the "All-Object Detection" button on the home screen to initiate the detection process.\n\n'
          '2. Camera Initialization:\n'
          '   - The app will automatically initialize the camera. Ensure you have granted the necessary permissions for camera access.\n'
          '   - Once initialized, the camera feed will appear on your screen.\n\n'
          '3. Real-Time Object Detection:\n'
          '   - As the app scans your surroundings, it will detect and highlight all visible objects in real-time.\n'
          '   - Detected objects will be displayed with bounding boxes, and the detection results will update continuously.\n\n'
          '4. Understanding the Feedback:\n'
          '   - A green status bar indicates that objects have been successfully detected.\n'
          '   - If objects are found, you will hear an audio feedback message, such as “Object detected” or “Objects detected,” and your device will vibrate for confirmation.\n'
          '   - A red status bar signifies that no objects were detected at that moment.\n\n'
          '5. Zoom Functionality:\n'
          '   - You can adjust the camera zoom level using the Zoom Slider located at the bottom of the screen.\n'
          '   - The current zoom level is displayed, and you can slide it to zoom in or out as needed.\n\n'
          '6. Flashlight Usage:\n'
          '   - To improve visibility in low-light conditions, use the Flash Button located in the top-right corner of the screen. This will toggle the camera flash on and off.\n\n'
          '7. Exiting the Feature:\n'
          '   - To return to the home screen, tap the back button provided on the screen.\n\n'
          'Tips for Best Results:\n'
          '- Ensure the camera lens is clean for optimal performance.\n'
          '- Move slowly around the area to allow the app to detect objects effectively.\n'
          '- For better recognition, try to keep objects within the camera’s view unobstructed.\n\n'
          'Troubleshooting:\n'
          '- If you encounter issues with object detection:\n'
          '   - Make sure your camera permissions are enabled in your device settings.\n'
          '   - Restart the app if the camera feed does not appear.\n'
          '   - Ensure you are in an environment with adequate lighting.',
    );
  }
}

class NavigateObjectHelpTab extends StatelessWidget {
  const NavigateObjectHelpTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _helpTab(
      title: 'Object Guidance',
      description:
      'Navigate to a specific object with guidance.\n\nSteps:\n1. Tap "Object Guidance".\n2. Select an object.\n3. Follow instructions to avoid obstacles and reach the object.',
    );
  }
}

// Helper function to generate a help tab design with white background and blue accents
Widget _helpTab({required String title, required String description}) {
  return Container(
    padding: const EdgeInsets.all(16.0),
    color: Colors.white, // Clean white background
    child: ListView(
      children: [
        HelpCard(
          title: title,
          description: description,
        ),
      ],
    ),
  );
}
