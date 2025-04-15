import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class AQIMeter extends StatefulWidget {
  final double value;
  final bool isPM2_5;

  const AQIMeter({super.key, required this.value, required this.isPM2_5});

  @override
  State<AQIMeter> createState() => _AQIMeterState();
}

class _AQIMeterState extends State<AQIMeter> {
  @override
  Widget build(BuildContext context) {
    double _devHeight = MediaQuery.of(context).size.height;
    return Center(
      child: Container(
        height: _devHeight * 0.05,
        margin: EdgeInsets.only(top: 10, bottom: 16),
        child:
            widget.isPM2_5
                ? SfLinearGauge(
                  minimum: 0,
                  maximum: 300,
                  markerPointers: [
                    LinearWidgetPointer(
                      value: widget.value,
                      child: Container(
                        height: 20,
                        width: 5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  ranges: [
                    LinearGaugeRange(
                      startValue: 0,
                      endValue: 15.5,
                      color: Colors.lightGreenAccent,
                    ),
                    LinearGaugeRange(
                      startValue: 15.5,
                      endValue: 55.4,
                      color: Colors.lightGreen,
                    ),
                    LinearGaugeRange(
                      startValue: 55.4,
                      endValue: 150.4,
                      color: Colors.yellow,
                    ),
                    LinearGaugeRange(
                      startValue: 150.4,
                      endValue: 250.4,
                      color: Colors.orangeAccent,
                    ),
                    LinearGaugeRange(
                      startValue: 250.4,
                      endValue: 300,
                      color: Colors.red,
                    ),
                  ],
                )
                : SfLinearGauge(
                  minimum: 0,
                  maximum: 500,
                  markerPointers: [
                    LinearWidgetPointer(
                      value: widget.value,
                      child: Container(
                        height: 20,
                        width: 5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  ranges: [
                    LinearGaugeRange(
                      startValue: 0,
                      endValue: 50,
                      color: Colors.lightGreenAccent,
                    ),
                    LinearGaugeRange(
                      startValue: 50,
                      endValue: 150,
                      color: Colors.lightGreen,
                    ),
                    LinearGaugeRange(
                      startValue: 150,
                      endValue: 350,
                      color: Colors.yellow,
                    ),
                    LinearGaugeRange(
                      startValue: 350,
                      endValue: 420,
                      color: Colors.orangeAccent,
                    ),
                    LinearGaugeRange(
                      startValue: 420,
                      endValue: 500,
                      color: Colors.red,
                    ),
                  ],
                ),
      ),
    );
  }
}
