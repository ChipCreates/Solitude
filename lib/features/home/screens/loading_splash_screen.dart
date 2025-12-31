import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadingSplashScreen extends StatefulWidget {
  const LoadingSplashScreen({super.key});

  @override
  State<LoadingSplashScreen> createState() => _LoadingSplashScreenState();
}

class _LoadingSplashScreenState extends State<LoadingSplashScreen>
    with SingleTickerProviderStateMixin {
  static bool _hasAnimated = false;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
      value: _hasAnimated ? 1.0 : 0.0,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );
    if (!_hasAnimated) {
      _progressController.forward();
      _hasAnimated = true;
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get the current screen size
    final Size screenSize = MediaQuery.of(context).size;
    
    // 2. Define the threshold (Native SVG size)
    const double assetSize = 2048.0;
    
    // 3. Determine scaling mode and orientation
    final bool isLandscape = screenSize.width > screenSize.height;
    final bool isLargeScreen = screenSize.width > assetSize || screenSize.height > assetSize;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1a1a1a),
        body: SizedBox.expand(
          child: Stack(
            children: [
              // --- Layer 1: Background ---
              Positioned.fill(
                child: Image.asset(
                  'assets/solitude-bg.webp',
                  // LOGIC:
                  // Landscape: Fit width to fill screen width
                  // Large screen: Cover (scale up)
                  // Small screen: None (crop center, no scale)
                  fit: isLandscape ? BoxFit.fitWidth : (isLargeScreen ? BoxFit.cover : BoxFit.none),
                  alignment: Alignment.center,
                  
                  // We only force dimensions when NOT scaling.
                  // When scaling (cover), we let the layout constraints handle it.
                  width: isLargeScreen ? null : assetSize,
                  height: isLargeScreen ? null : assetSize,
                ),
              ),

              // --- Layer 2: Content ---
              Positioned.fill(
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/solitude-logo.svg',
                          width: isLandscape ? 450 : 150,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Solitude',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: isLandscape ? 60 : 40,
                            color: Colors.white,
                            letterSpacing: 1.2,
                            shadows: const [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 4.0,
                                color: Color.fromRGBO(0, 0, 0, 0.5),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Progress Bar
                        SizedBox(
                          width: 220,
                          child: AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(1.5),
                                  color: Colors.black.withValues(alpha: 0.3),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(1.5),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _progressAnimation.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withValues(alpha: 0.5),
                                            blurRadius: 5,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Shuffling the deck...',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(flex: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}