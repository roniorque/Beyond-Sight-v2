import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_page.dart'; // Update this with the correct path to your HomePage

class BackButtonWidget extends StatelessWidget {
  const BackButtonWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      left: 10,
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24), // Adjust size as needed
        onPressed: () {
          // Navigate back with smooth transition
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                return HomePage(); // Ensure HomePage is imported correctly
              },
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                // Begin and end scale values for the zoom out effect
                const beginScale = 1.0;
                const endScale = 1.0; // Keep it at 1.0 to avoid zooming
                const curve = Curves.easeInOut; // Smooth curve for a modern feel

                // Scaling transition
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
                      width: MediaQuery.of(context).size.width, // Full width
                      height: MediaQuery.of(context).size.height, // Full height
                      child: child, // Pass the child widget
                    ),
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 800), // Duration of the transition
            ),
          ).then((_) {
            // Enable immersive mode after returning to HomePage
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          });
        },
      ),
    );
  }
}
