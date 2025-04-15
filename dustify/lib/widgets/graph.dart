import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:dustify/services/ble_manager.dart';

class LineGraph extends StatefulWidget {
  final bool isPM2_5;

  const LineGraph({super.key, required this.isPM2_5});

  @override
  State<LineGraph> createState() => _LineGraphState();
}

class _LineGraphState extends State<LineGraph> {
  final List<FlSpot> _pm25Spots = [];
  final List<FlSpot> _pm10Spots = [];
  int _index = 0;
  StreamSubscription<Map<String, double>>? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _initializeGraph();
  }

  Future<void> _initializeGraph() async {
    await BLEManager().loadRecentData();

    final pm25List = BLEManager().last60PM25;
    final pm10List = BLEManager().last60PM10;

    setState(() {
      for (int i = 0; i < pm25List.length; i++) {
        _pm25Spots.add(FlSpot(i.toDouble(), pm25List[i]));
      }
      for (int i = 0; i < pm10List.length; i++) {
        _pm10Spots.add(FlSpot(i.toDouble(), pm10List[i]));
      }
      _index = pm25List.length;
    });

    _dataSubscription = BLEManager().parsedDataStream.listen((data) {
      try {
        double pm25 = data['PM2.5'] ?? 0;
        double pm10 = data['PM10'] ?? 0;

        setState(() {
          _pm25Spots.add(FlSpot(_index.toDouble(), pm25));
          _pm10Spots.add(FlSpot(_index.toDouble(), pm10));

          if (_pm25Spots.length > 60) _pm25Spots.removeAt(0);
          if (_pm10Spots.length > 60) _pm10Spots.removeAt(0);

          for (int i = 0; i < _pm25Spots.length; i++) {
            _pm25Spots[i] = FlSpot(i.toDouble(), _pm25Spots[i].y);
            _pm10Spots[i] = FlSpot(i.toDouble(), _pm10Spots[i].y);
          }

          _index++;
          if (_index > 10000) _index = 0;
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
    double devHeight = MediaQuery.of(context).size.height;
    double devWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Container(
          color: Colors.black12,
          height: devHeight * 0.3,
          width: devWidth,
          child:
              widget.isPM2_5
                  ? _buildGraph(isPM2_5: true)
                  : _buildGraph(isPM2_5: false),
        ),
      ],
    );
  }

  Widget _buildGraph({required bool isPM2_5}) {
    return _pm25Spots.isEmpty || _pm10Spots.isEmpty
        ? Center(child: CircularProgressIndicator(color: Colors.orange))
        : isPM2_5
        ? LineChart(
          LineChartData(
            minY: 0,
            maxY: 500,
            minX: 0,
            maxX: 60,
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 100,
                  reservedSize: 40,
                  getTitlesWidget:
                      (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 10,
                  reservedSize: 32,
                  getTitlesWidget:
                      (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: _pm25Spots,
                isCurved: true,
                curveSmoothness: 0.3,
                preventCurveOverShooting: true,
                color: Colors.orange,
                barWidth: 3,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(show: false),
                dotData: FlDotData(show: false),
              ),
            ],
          ),
        )
        : LineChart(
          LineChartData(
            minY: 0,
            maxY: 500,
            minX: 0,
            maxX: 60,
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 100,
                  reservedSize: 40,
                  getTitlesWidget:
                      (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 10,
                  reservedSize: 32,
                  getTitlesWidget:
                      (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: _pm10Spots,
                isCurved: true,
                curveSmoothness: 0.3,
                preventCurveOverShooting: true,
                color: Colors.lightBlueAccent,
                barWidth: 3,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(show: false),
                dotData: FlDotData(show: false),
              ),
            ],
          ),
        );
  }
}
