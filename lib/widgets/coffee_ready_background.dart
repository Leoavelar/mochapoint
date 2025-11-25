import 'package:flutter/material.dart';

class CoffeeReadyBackground extends StatefulWidget {
  final double width;
  final double height;
  final Widget? child;
  final VoidCallback? onTap;

  const CoffeeReadyBackground({
    super.key,
    this.width = double.infinity,
    this.height = 200,
    this.child,
    this.onTap, 
  });

  @override
  State<CoffeeReadyBackground> createState() => _CoffeeReadyBackgroundState();
}

class _CoffeeReadyBackgroundState extends State<CoffeeReadyBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    // Configure the continuous shine animation loop
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // DESIGN TOKENS
    const Color cardDarkBg = Color(0xFF2C2C2E);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        // The container decoration (Dark Card Base)
        decoration: BoxDecoration(
          color: cardDarkBg,
          borderRadius: BorderRadius.circular(24), // rounded-[2.5rem]
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          // Deep shadow to lift it off the page
          boxShadow: [
            BoxShadow(
              color: cardDarkBg.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          // Subtle internal gradient to give depth to the dark surface
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardDarkBg,
              Color(0xFF000000),
            ],
          ),
        ),
        // ClipRRect is needed to contain the overflow of the Shine Effect
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // 1. Static Subtle Diagonal Sheen (Optional, adds static texture)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 2. THE SHINE ANIMATION
              AnimatedBuilder(
                animation: _shineController,
                builder: (context, child) {
                  // Logic to sweep the gradient across the card
                  // We map 0.0->1.0 to a translation range that covers the width
                  return Positioned(
                    top: -100,
                    bottom: -100,
                    left: 0,
                    right: 0,
                    child: Transform.translate(
                      offset: Offset(
                        // Move from left (-width) to right (+width)
                        (MediaQuery.of(context).size.width * 1.5) * (_shineController.value - 0.5),
                        0,
                      ),
                      // Rotate the shine bar 45 degrees
                      child: Transform.rotate(
                        angle: 45 * 3.14159 / 180,
                        child: Container(
                          width: 100, // Width of the shine beam
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.1), // Center of shine (brightest)
                                Colors.white.withOpacity(0.0),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // 3. The Content (passed as child)
              if (widget.child != null)
                Positioned.fill(child: widget.child!),
            ],
          ),
        ),
      ),
    );
  }
}