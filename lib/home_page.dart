import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'detect_all_objects_page.dart';
import 'navigate_to_object.dart';
import 'help_page.dart';
import 'settings_page.dart'; // Import the SettingsPage

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Set immersive mode when the home page is opened
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate font and icon sizes based on device width
    final double iconSize = screenWidth * 0.15; // 15% of the screen width for larger icon size
    final double labelFontSize = screenWidth * 0.06; // 6% of the screen width for larger label font size
    final double descriptionFontSize = screenWidth * 0.04; // 4% of the screen width for larger description font size

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.blueAccent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 60), // Adjusted gap to move the content down
                const Text(
                  'Beyond Sight',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Select an option below to get started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 50), // Adjust spacing to move buttons down a little bit
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 columns for buttons
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 30, // Vertical spacing between buttons
                        childAspectRatio: 0.6, // Decrease aspect ratio for taller buttons
                      ),
                      itemCount: _buttonData.length, // Number of buttons
                      itemBuilder: (context, index) {
                        return _buildGridButton(
                          context,
                          _buttonData[index]['label'] as String,
                          _buttonData[index]['icon'] as IconData,
                          _buttonData[index]['route'] as String,
                          _buttonData[index]['description'] as String,
                          iconSize,
                          labelFontSize,
                          descriptionFontSize,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  final List<Map<String, dynamic>> _buttonData = [
    {
      'label': 'Object Search',
      'icon': Icons.search,
      'route': '/object_detection',
      'description': 'Locate individual objects in your surroundings.',
    },
    {
      'label': 'All-Object Detection',
      'icon': Icons.blur_on_outlined,
      'route': '/detect_all_objects',
      'description': 'Identify all objects in the environment.',
    },
    {
      'label': 'Object Guidance',
      'icon': Icons.blind_rounded,
      'route': '/navigate_to_object',
      'description': 'Get guidance to navigate toward a specific object.',
    },
    {
      'label': 'Help',
      'icon': Icons.help,
      'route': '/help',
      'description': 'Learn how to use the app and find assistance.',
    },
  ];

  Widget _buildGridButton(BuildContext context, String label, IconData icon, String route, String description,
      double iconSize, double labelFontSize, double descriptionFontSize) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(20),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: () {
        if (route == '/detect_all_objects') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DetectAllObjectsPage()),
          );
        } else if (route == '/navigate_to_object') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NavigateToObjectScreen()),
          );
        } else if (route == '/help') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HelpPage()),
          );
        } else {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(fontSize: labelFontSize, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(fontSize: descriptionFontSize, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
