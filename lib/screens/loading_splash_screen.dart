import 'package:flutter/material.dart';

/// Splash screen shown during asset preloading.
/// Displays while SVG assets are being loaded and cached.
class LoadingSplashScreen extends StatefulWidget {
  const LoadingSplashScreen({super.key});

  @override
  State<LoadingSplashScreen> createState() => _LoadingSplashScreenState();
}

class _LoadingSplashScreenState extends State<LoadingSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF3A3A3C),
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate responsive dimensions based on screen width
            final screenWidth = constraints.maxWidth;

            // Progress bar width: 60% of screen width, clamped between 200-400px
            final progressBarWidth = (screenWidth * 0.6).clamp(200.0, 400.0);

            // Height is 1/12 of width (maintaining aspect ratio)
            // This gives us ~17px on mobile, ~20px on tablets, ~33px on large screens
            final progressBarHeight = progressBarWidth / 12;
            final borderRadius = progressBarHeight / 2;

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App icon - no drop shadow
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/icon.jpg',
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 200,
                          color: const Color(0xFF2A2A2A),
                          child: const Center(
                            child: Icon(
                              Icons.casino,
                              size: 80,
                              color: Colors.white54,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Progress bar with glossy treatment (responsive)
                  SizedBox(
                    width: progressBarWidth,
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Container(
                          height: progressBarHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(borderRadius),
                            color: Colors.white.withValues(alpha:0.15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha:0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(borderRadius),
                            child: Stack(
                              children: [
                                // Progress fill
                                FractionallySizedBox(
                                  widthFactor: _progressAnimation.value,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFF5BA3F5), // Lighter blue
                                          Color(0xFF4A90E2), // Base blue
                                          Color(0xFF3A7BC8), // Darker blue
                                        ],
                                        stops: [0.0, 0.5, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                // Glossy overlay
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.white.withValues(alpha:0.4),
                                          Colors.white.withValues(alpha:0.1),
                                          Colors.transparent,
                                          Colors.black.withValues(alpha:0.1),
                                        ],
                                        stops: const [0.0, 0.3, 0.7, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Loading text
                  const Text(
                    'Shuffling the deck...',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Colors.white60,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
