import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // Required for TapGestureRecognizer
import 'home_page.dart';
import 'package:permission_handler/permission_handler.dart'; // Import the permission handler
import 'package:vibration/vibration.dart'; // Import the vibration package

class PermissionsPage extends StatefulWidget {
  @override
  _PermissionsPageState createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  bool _cameraGranted = false;
  bool _microphoneGranted = false;
  bool _hapticFeedbackGranted = false; // Default is off
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions(); // Just check the status without requesting
  }

  void _checkPermissions() async {
    // Check camera permission
    var cameraStatus = await Permission.camera.status;
    setState(() {
      _cameraGranted = cameraStatus.isGranted;
    });

    // Check microphone permission
    var microphoneStatus = await Permission.microphone.status;
    setState(() {
      _microphoneGranted = microphoneStatus.isGranted;
    });

    // Check haptic feedback capability
    _hapticFeedbackGranted = await Vibration.hasVibrator() ?? false;
  }

  bool get _allPermissionsGranted =>
      _cameraGranted && _microphoneGranted && _hapticFeedbackGranted && _acceptedTerms;

  void _requestCameraPermission() async {
    if (!_cameraGranted) {
      var cameraStatus = await Permission.camera.request();
      setState(() {
        _cameraGranted = cameraStatus.isGranted;
      });
    }
  }

  void _requestMicrophonePermission() async {
    if (!_microphoneGranted) {
      var microphoneStatus = await Permission.microphone.request();
      setState(() {
        _microphoneGranted = microphoneStatus.isGranted;
      });
    }
  }
  Future<void> _requestHapticFeedback() async {
    // Check if the device has a vibrator
    bool hasVibrator = await Vibration.hasVibrator() ?? false;

    if (hasVibrator) {
      // Toggle the haptic feedback status
      setState(() {
        _hapticFeedbackGranted = !_hapticFeedbackGranted; // Toggle haptic feedback status
        if (_hapticFeedbackGranted) {
          Vibration.vibrate(); // Trigger a short vibration if enabled
        }
      });
    }
  }

  void _navigateToHomePage(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Scale and fade effect for a delving transition
          const begin = 0.8; // Start slightly scaled down
          const end = 1.0; // End with full scale
          const curve = Curves.easeInOut; // Smooth transition curve

          // Define a scale tween
          var scaleTween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var scaleAnimation = animation.drive(scaleTween);

          // Fade transition
          var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ));

          // Use a Transform widget to apply the scale and create a delving effect
          return ScaleTransition(
            scale: scaleAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 800), // Duration can be adjusted
      ),
    );
  }


  void _openDocument(BuildContext context, String title, String filePath, int initialTabIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentView(title: title, filePath: filePath, initialTabIndex: initialTabIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.blueAccent], // Black to blue gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 50),
            Text(
              'PERMISSIONS',
              style: TextStyle(
                fontSize: 28, // Increased font size for modern look
                fontWeight: FontWeight.bold,
                color: Colors.white, // Changed color to white
                shadows: [
                  Shadow(
                    blurRadius: 5.0,
                    color: Colors.black.withOpacity(0.5),
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'To enhance your experience, we need permission to access the following features:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white, // Changed text color to white
                  shadows: [
                    Shadow(
                      blurRadius: 5.0,
                      color: Colors.black.withOpacity(0.5),
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            _buildPermissionTile(
              context,
              'Camera',
              _cameraGranted,
              Icons.camera_alt_outlined,
                  () {
                _requestCameraPermission(); // Request permission when the tile is tapped
              },
            ),
            SizedBox(height: 20),
            _buildPermissionTile(
              context,
              'Microphone',
              _microphoneGranted,
              Icons.mic_none_outlined,
                  () {
                _requestMicrophonePermission(); // Request permission when the tile is tapped
              },
            ),
            SizedBox(height: 20),
            _buildPermissionTile(
              context,
              'Haptic Feedback',
              _hapticFeedbackGranted,
              Icons.vibration_outlined,
                  () {
                _requestHapticFeedback(); // Toggle haptic feedback
              },
            ), // Use a comma here to separate from the next widget
            SizedBox(height: 30),
            // Privacy policy toggle positioned directly above the button
            _buildTermsAndConditionsToggle(context),
            SizedBox(height: 20),
            // "Allow" button positioned below the privacy policy toggle
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ElevatedButton(
                child: Text('Allow'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.2,
                    vertical: 15,
                  ),
                  textStyle: TextStyle(fontSize: 18),
                  backgroundColor: _allPermissionsGranted ? Colors.black : Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  minimumSize: Size(MediaQuery.of(context).size.width * 0.8, 50),
                ),
                onPressed: _allPermissionsGranted
                    ? () => _navigateToHomePage(context)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPermissionTile(
      BuildContext context, String label, bool granted, IconData icon, Function() toggle) {
    return GestureDetector(
      onTap: toggle,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: granted ? Colors.blueAccent.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(5), // Less rounded corners
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Checkbox(
              value: granted,
              activeColor: Colors.black, // Changed checkmark color
              onChanged: (bool? value) {
                toggle();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsAndConditionsToggle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Checkbox(
            value: _acceptedTerms,
            activeColor: Colors.black, // Changed checkmark color
            onChanged: (bool? value) {
              setState(() {
                _acceptedTerms = value ?? false;
              });
            },
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: 'I read the ',
                style: TextStyle(fontSize: 14, color: Colors.white),
                children: [
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: Color(0xFF022B59),
                      fontSize: 14,
                      decoration: TextDecoration.underline, // Add underline here
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        _openDocument(context, 'Privacy Policy', 'assets/privacy_policy.txt', 1); // Pass 1 for "Data & Privacy" tab
                      },
                  ),
                  TextSpan(
                    text: ' and I accept the ',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  TextSpan(
                    text: 'Terms and Conditions',
                    style: TextStyle(
                      color: Color(0xFF022B59),
                      fontSize: 14,
                      decoration: TextDecoration.underline, // Add underline here
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        _openDocument(context, 'Terms and Conditions', 'assets/terms_conditions.txt', 0); // Pass 0 for "Usage & Safety"
                      },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentView extends StatefulWidget {
  final String filePath;
  final int initialTabIndex; // Property to pass the initial tab index

  DocumentView({
    required this.filePath,
    this.initialTabIndex = 0, required String title, // Default to 0 if not provided
  });

  @override
  _DocumentViewState createState() => _DocumentViewState();
}

class _DocumentViewState extends State<DocumentView> {
  late int _selectedTabIndex;

  @override
  void initState() {
    super.initState();
    // Set the initial tab index based on what's passed when the page is opened
    _selectedTabIndex = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.blue), // Blue back button
            onPressed: () => Navigator.of(context).pop(), // Go back on pressed
          ),
          backgroundColor: Colors.white, // Clean white background for AppBar
          bottom: TabBar(
            indicatorColor: Colors.blue,
            indicatorWeight: 3.0,
            labelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            labelColor: Colors.blue, // Blue for active tab
            unselectedLabelColor: Colors.black, // Black for inactive tabs
            tabs: [
              Tab(text: 'Terms & Conditions'), // Tab 1
              Tab(text: 'Privacy Policy'),      // Tab 2
            ],
          ),
        ),
        body: Container(
          color: Colors.white, // Full white background for the content area
          child: TabBarView(
            children: [
              _helpTab(
                title: 'Terms & Conditions',
                description: _getDocumentContent('Terms & Conditions'),
              ),
              _helpTab(
                title: 'Privacy Policy',
                description: _getDocumentContent('Privacy Policy'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _helpTab({required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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

  String _getDocumentContent(String title) {
    if (title == 'Terms & Conditions') {
      return '''Terms and Conditions - Usage & Safety

Welcome to Beyond Sight. By using this application, you agree to adhere to the following terms:

- General Usage: Users must ensure that their use of Beyond Sight complies with local laws and regulations.
- Obstacle Detection: Beyond Sight uses advanced algorithms to detect obstacles in the user's surroundings and provide voice feedback.
- Voice-Assisted Navigation: This feature helps users reach their destination using auditory cues.
- User Responsibility: Users are responsible for their safety when relying on the app's features.

By continuing to use Beyond Sight, you agree to these terms.''';
    } else if (title == 'Privacy Policy') {
      return '''Privacy Policy - Data & Privacy

At Beyond Sight, we are dedicated to safeguarding your privacy and your data:

- Information Collection: We collect personal data such as your location, device information, and usage data to enhance your experience.
- Data Usage: Your information is used solely to improve our services and provide personalized features.
- Data Protection: We implement industry-standard security measures to protect your data from unauthorized access.
- User Rights: You have the right to access, modify, or delete your personal data at any time.

By using Beyond Sight, you consent to this Privacy Policy and its terms.''';
    } else {
      return '';
    }
  }
}

class HelpCard extends StatelessWidget {
  final String title;
  final String description;

  const HelpCard({Key? key, required this.title, required this.description}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white, // White background for cards
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.blue, width: 1.5), // Blue border for modern look
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black, // Black text for title
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87, // Black text for description
              ),
            ),
          ],
        ),
      ),
    );
  }
}
