import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:simple_ripple_animation/simple_ripple_animation.dart';

class Splace_Screen extends StatelessWidget {
  const Splace_Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: RippleAnimation(
          color: Colors.deepPurpleAccent, // Customize the ripple color
          delay: const Duration(milliseconds: 400), // Delay before the ripple starts
          minRadius: 150, // Minimum radius of the ripple effect
          ripplesCount: 10, // Number of ripples
          repeat: true, // Repeat the animation
          duration: const Duration(milliseconds: 4200), // Duration of each ripple
          child: Container(
            width: 290,
            height: 290,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white, // Background color of the logo container
            ),
            child: ClipOval(
              child: Center(
                child: Image.asset(
                  'assets/icons/tvs.jpg',
                  height: 220,
                  width: 220,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
