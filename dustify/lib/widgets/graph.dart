import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class RealTimeGraph extends StatelessWidget {
  final List<FlSpot> chartData;

  const RealTimeGraph({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Live Data Graph",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Container(
          height: 200,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: LineChart(
            LineChartData(
              backgroundColor: Colors.black12,
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: chartData,
                  isCurved: true,
                  color: Colors.orangeAccent,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                  barWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
