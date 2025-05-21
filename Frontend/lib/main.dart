import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz.initializeTimeZones();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String voltage = 'Loading...';
  String wattage = 'Loading...';
  String kWh = 'Loading...';
  List<dynamic> readingsHistory = [];

  final Dio _dio = Dio();
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    fetchData();

    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      fetchData();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      final response = await _dio.get(
        'https://app-dev-backend.onrender.com/data',
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data.isNotEmpty) {
          final latestReading = data.last;
          setState(() {
            voltage =
                '${double.tryParse(latestReading['voltage'].toString()) ?? 0.0}V';
            wattage =
                '${double.tryParse(latestReading['power'].toString()) ?? 0.0}W';
            kWh =
                '${double.tryParse(latestReading['kwh'].toString()) ?? 0.0}kWh';
            readingsHistory = data.reversed.toList();
          });
        }
      } else {
        setState(() {
          voltage = 'Error';
          wattage = 'Error';
          kWh = 'Error';
        });
      }
    } catch (e) {
      print('Failed to fetch data: $e');
      setState(() {
        voltage = 'Error';
        wattage = 'Error';
        kWh = 'Error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appliance Monitor')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                isWide
                    ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _buildInfoCards(isWide),
                    )
                    : Column(children: _buildInfoCards(isWide)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: fetchData,
                  child: const Text('Refresh Data'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'History:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: readingsHistory.length,
                  itemBuilder: (context, index) {
                    final reading = readingsHistory[index];
                    String timestamp = 'Unknown time';
                    if (reading['timestamp'] != null) {
                      final parsedTime = DateTime.tryParse(
                        reading['timestamp'],
                      );
                      if (parsedTime != null) {
                        final philippineTime = tz.TZDateTime.from(
                          parsedTime,
                          tz.getLocation('Asia/Manila'),
                        );
                        timestamp = DateFormat(
                          'hh:mm a - MM-dd-yyyy',
                        ).format(philippineTime);
                      }
                    }

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          "Voltage: ${reading['voltage']}V, Power: ${reading['power']}W, kWh: ${reading['kwh']}",
                        ),
                        subtitle: Text("Time: $timestamp"),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildInfoCards(bool isWide) {
    final cards = [
      _buildCard('Voltage', voltage, Color(0xFFA2D2FF)),
      _buildCard('Wattage', wattage, Color(0xFFFFD6A5)),
      _buildCard('kWh', kWh, Color(0xFFB5E48C)),
    ];

    if (isWide) {
      return cards.map((card) => Expanded(child: card)).toList();
    } else {
      return cards;
    }
  }

  Widget _buildCard(String label, String value, Color color) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
