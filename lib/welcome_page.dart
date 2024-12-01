import 'package:flutter/material.dart';
import 'permissions_page.dart'; // Link to permissions page
import 'package:flutter/services.dart'; // For immersive mode

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin {
  bool _showButton = false; // Track whether to show the button
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Set immersive mode to hide system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Set up animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true); // Repeat the animation

    _animation = Tween<double>(begin: 0.0, end: 10.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Delay to show the button
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _showButton = true; // Show the button after 3 seconds
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToPermissionsPage(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PermissionsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0); // Slide from the right
          const end = Offset.zero; // End at the original position
          const curve = Curves.easeInOut; // Animation curve

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          // Fade transition
          var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ));

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.blueAccent], // Black at the top to Blue at the bottom
            begin: Alignment.topCenter, // Start gradient from top
            end: Alignment.bottomCenter, // End gradient at bottom
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Removed circular cutout for the logo
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.35,
                width: MediaQuery.of(context).size.height * 0.35,
                child: Image.asset('assets/welcome_logo.png', fit: BoxFit.cover), // Transparent logo
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Welcome to Beyond Sight! This application is designed to assist users with visual impairments in identifying objects and navigating their environment using advanced technology.',
                  textAlign: TextAlign.center, // Center the text
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white, // Change text color to white
                  ),
                ),
              ),
              SizedBox(height: 70),
              AnimatedOpacity(
                opacity: _showButton ? 1.0 : 0.0,
                duration: Duration(seconds: 1),
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_animation.value, 0),
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.arrow_forward, size: 24),
                        label: Text('Get Started'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.2, vertical: 15),
                          textStyle: TextStyle(fontSize: 18),
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () => _navigateToPermissionsPage(context),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
