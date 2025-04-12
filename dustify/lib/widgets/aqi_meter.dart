import 'package:flutter/material.dart';

class AQIMeter extends StatefulWidget {
  final double value; // µg/m³
  final bool isPM2_5; // Flag to determine whether it's PM2.5 or PM10

  const AQIMeter({super.key, required this.value, required this.isPM2_5});

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
    Colors.red,
  ];

  final List<String> _labels = [
    "Very Good",
    "Good",
    "Fair",
    "Poor",
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

  double _calculatePosition(double value) {
    if (widget.isPM2_5) {
      if (value <= 15.5) return 0;
      if (value <= 55.4) return 1;
      if (value <= 150.4) return 2;
      if (value <= 250.4) return 3;
      return 4;
    } else {
      // PM10
      if (value <= 50) return 0;
      if (value <= 150) return 1;
      if (value <= 350) return 2;
      if (value <= 420) return 3;
      return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final sectionWidth = totalWidth / 5; // 5 sections instead of 6

            return Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Color.fromRGBO(208, 208, 208, 1), // Gray border
                  width: 2, // Border width
                ),
                borderRadius: BorderRadius.circular(4), // Rounded corners
              ),
              child: Stack(
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
                        left:
                            _animation.value * sectionWidth, // Map to sections
                        top: 0,
                        child: Container(
                          width: 6, // Thinner bar
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
              ),
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
