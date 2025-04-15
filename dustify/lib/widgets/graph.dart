import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:dustify/services/ble_manager.dart';

class LineGraph extends StatefulWidget {
  const LineGraph({super.key});

  @override
  State<LineGraph> createState() => _LineGraphState();
}

class _LineGraphState extends State<LineGraph> {
  List<FlSpot> _pm25Spots = [];
  List<FlSpot> _pm10Spots = [];
  int _index = 0;
  StreamSubscription<Map<String, double>>? _dataSubscription;

  @override
  void initState() {
    super.initState();

    _dataSubscription = BLEManager().parsedDataStream.listen((data) {
      try {
        double pm25 = data['PM2.5'] ?? 0;
        double pm10 = data['PM10'] ?? 0;

        setState(() {
          _pm25Spots.add(FlSpot(_index.toDouble(), pm25));
          _pm10Spots.add(FlSpot(_index.toDouble(), pm10));

          if (_pm25Spots.length > 20) _pm25Spots.removeAt(0);
          if (_pm10Spots.length > 20) _pm10Spots.removeAt(0);

          _index++;
        });
      } catch (e) {
        debugPrint('Error updating graph data: $e');
      }
    });
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double _devHeight = MediaQuery.of(context).size.height;
    double _devWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Container(
          color: Colors.black12,
          height: _devHeight * 0.25,
          width: _devWidth,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child:
              (_pm25Spots.isEmpty || _pm10Spots.isEmpty)
                  ? Center(
                    child: Text(
                      "Waiting for data...",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                  : LineChart(
                    LineChartData(
                      minY: 0,
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _pm25Spots,
                          isCurved: true,
                          color: Colors.orange,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          belowBarData: BarAreaData(show: false),
                          dotData: FlDotData(show: false),
                        ),
                        LineChartBarData(
                          spots: _pm10Spots,
                          isCurved: true,
                          color: Colors.lightBlueAccent,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          belowBarData: BarAreaData(show: false),
                          dotData: FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(color: Colors.orange, label: "PM2.5"),
              const SizedBox(width: 16),
              _buildLegendItem(color: Colors.lightBlueAccent, label: "PM10"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
