import 'package:flutter/material.dart';

class RadarAnimation extends StatefulWidget {
  final double size;
  final Color color;

  const RadarAnimation({
    super.key,
    this.size = 120.0,
    this.color = const Color(0xFF00D1FF),
  });

  @override
  State<RadarAnimation> createState() => _RadarAnimationState();
}

class _RadarAnimationState extends State<RadarAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Expanding circles
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Offset the animation for each circle
                double value = (_controller.value + (index * 0.33)) % 1.0;
                
                // Opacity fades out as it expands
                double opacity = 1.0 - value;
                
                // Scale goes from 0 to 1
                double scale = value;

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.color.withValues(alpha: opacity * 0.5),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: opacity * 0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
          
          // Center Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF112240),
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.color.withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              Icons.sensors,
              color: widget.color,
              size: widget.size * 0.25,
            ),
          ),
        ],
      ),
    );
  }
}
