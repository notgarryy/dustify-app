import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dustify/services/firebase_manager.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get_it/get_it.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  FirebaseService? _firebaseService;

  double? devHeight, devWidth;
  bool? hasUser;

  @override
  void initState() {
    super.initState();
    _firebaseService = GetIt.instance.get<FirebaseService>();
    final loggedInUser = _firebaseService?.currentFirebaseUser;
    hasUser = loggedInUser != null;
  }

  double clipValue(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    devHeight = MediaQuery.of(context).size.height;
    devWidth = MediaQuery.of(context).size.width;

    if (hasUser == false) {
      return const Scaffold(
        backgroundColor: Color.fromRGBO(34, 31, 31, 1),
        body: Center(
          child: Text(
            'Please login to view history.',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromRGBO(34, 31, 31, 1),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseService!.getAllPmDataStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No history data.'));
          }

          final docs = snapshot.data!.docs;

          // Group data by day
          Map<String, List<Map<String, dynamic>>> groupedData = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = (data['timestamp'] as Timestamp).toDate();
            final dayKey = _formatDate(timestamp);

            if (!groupedData.containsKey(dayKey)) {
              groupedData[dayKey] = [];
            }
            groupedData[dayKey]!.add(data);
          }

          // Sort each day's data ascending by timestamp
          for (var day in groupedData.keys) {
            groupedData[day]!.sort((a, b) {
              DateTime tA = (a['timestamp'] as Timestamp).toDate();
              DateTime tB = (b['timestamp'] as Timestamp).toDate();
              return tA.compareTo(tB);
            });
          }

          // Sort days descending (newest first)
          final sortedDays =
              groupedData.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            itemCount: sortedDays.length,
            itemBuilder: (context, index) {
              final day = sortedDays[index];
              final dayData = groupedData[day]!;

              double totalPm25 = 0;
              double totalPm10 = 0;

              for (var data in dayData) {
                totalPm25 += (data['avgPM25'] ?? 0).toDouble();
                totalPm10 += (data['avgPM10'] ?? 0).toDouble();
              }

              double avgPm25 = totalPm25 / dayData.length;
              double avgPm10 = totalPm10 / dayData.length;

              List<FlSpot> pm25Spots = [];
              List<FlSpot> pm10Spots = [];

              // Clip nilai sebelum dimasukkan ke FlSpot supaya tidak overshoot
              for (int i = 0; i < dayData.length; i++) {
                pm25Spots.add(
                  FlSpot(
                    i.toDouble(),
                    clipValue(dayData[i]['avgPM25']?.toDouble() ?? 0, 0, 300),
                  ),
                );
                pm10Spots.add(
                  FlSpot(
                    i.toDouble(),
                    clipValue(dayData[i]['avgPM10']?.toDouble() ?? 0, 0, 300),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  color: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      collapsedIconColor: Colors.orange,
                      iconColor: Colors.orange,
                      title: Text(
                        _formatFullDate(day),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Average PM2.5 Hourly Data: ${avgPm25.toStringAsFixed(1)} µg/m³",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Average PM10 Hourly Data : ${avgPm10.toStringAsFixed(1)} µg/m³",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      expandedAlignment: Alignment.centerLeft,
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      childrenPadding: const EdgeInsets.all(10),
                      children: [
                        Container(
                          margin: const EdgeInsets.only(left: 20),
                          child: const Text(
                            "Daily Data: ",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 20,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'PM2.5',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    color: Colors.lightBlueAccent,
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'PM10',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Center(
                          child: SizedBox(
                            height: 250,
                            width: devWidth! * 0.85,
                            child: LineChart(
                              LineChartData(
                                clipData: FlClipData.all(), // <-- tambahkan ini
                                gridData: FlGridData(
                                  show: true,
                                  getDrawingHorizontalLine:
                                      (value) => FlLine(
                                        color: Colors.white,
                                        strokeWidth: 1,
                                      ),
                                  getDrawingVerticalLine:
                                      (value) => FlLine(
                                        color: Colors.white,
                                        strokeWidth: 1,
                                      ),
                                ),
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
                                      interval: 1,
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
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: true),
                                minX: 0,
                                maxX: (dayData.length - 1).toDouble(),
                                minY: 0,
                                maxY: 300,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: pm25Spots,
                                    isCurved: true,
                                    curveSmoothness: 0.15,
                                    preventCurveOverShooting: true,
                                    color: Colors.orange,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    belowBarData: BarAreaData(show: false),
                                    dotData: FlDotData(show: false),
                                  ),
                                  LineChartBarData(
                                    spots: pm10Spots,
                                    isCurved: true,
                                    curveSmoothness: 0.15,
                                    preventCurveOverShooting: true,
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
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatFullDate(String day) {
    DateTime parsedDate = DateTime.parse(day); // Convert the string to DateTime
    return DateFormat(
      'EEEE, dd MMMM yyyy',
    ).format(parsedDate); // Format to full date
  }
}
