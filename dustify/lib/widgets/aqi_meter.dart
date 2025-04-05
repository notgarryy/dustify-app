import 'package:flutter/material.dart';

class AQIMeter extends StatefulWidget {
  final int value; // µg/m³

  const AQIMeter({super.key, required this.value});

  @override
  State<AQIMeter> createState() => _AQIMeterState();
}

class _AQIMeterState extends State<AQIMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  double _normalizedPosition = 0;

  final List<Color> _colors = [
    Colors.lightGreen,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.brown,
    Colors.red,
  ];

  final List<String> _labels = [
    "Very Good",
    "Good",
    "Fair",
    "Poor",
    "Very Poor",
    "Hazardous",
  ];

  @override
  void initState() {
    super.initState();
    _normalizedPosition = _calculatePosition(widget.value);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(
      begin: 0,
      end: _normalizedPosition,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AQIMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    double newPos = _calculatePosition(widget.value);
    _animation = Tween<double>(
      begin: _animation.value,
      end: newPos,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _calculatePosition(int value) {
    if (value <= 12) return 0 / 6;
    if (value <= 35) return 1 / 6;
    if (value <= 55) return 2 / 6;
    if (value <= 150) return 3 / 6;
    if (value <= 250) return 4 / 6;
    return 5 / 6;
  }

  int _getAQIIndex(int value) {
    if (value <= 12) return 0;
    if (value <= 35) return 1;
    if (value <= 55) return 2;
    if (value <= 150) return 3;
    if (value <= 250) return 4;
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final sectionWidth = totalWidth / 6;

            return Stack(
              children: [
                Row(
                  children:
                      _colors
                          .map(
                            (color) => Expanded(
                              child: Container(height: 20, color: color),
                            ),
                          )
                          .toList(),
                ),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Positioned(
                      left: _animation.value * totalWidth,
                      top: 0,
                      child: Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:
              _labels
                  .map(
                    (label) => Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}
