import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Time Announcer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TimeAnnouncerScreen(),
    );
  }
}

class TimeAnnouncerScreen extends StatefulWidget {
  const TimeAnnouncerScreen({super.key});

  @override
  _TimeAnnouncerScreenState createState() => _TimeAnnouncerScreenState();
}

class _TimeAnnouncerScreenState extends State<TimeAnnouncerScreen> {
  TextEditingController _frequencyController = TextEditingController();
  TextEditingController _repeaterController = TextEditingController();
  Timer? _timer;
  FlutterTts flutterTts = FlutterTts();
  bool _isSpeaking = false;
  var repeaterCount = 3;
  // ignore: non_constant_identifier_names
  var CurrentTime = '--:-- --';
  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
  }

  void _startAnnouncing() {
    final frequencyText = _frequencyController.text;
    final repeaterCountText = _repeaterController.text;
    if (frequencyText.isEmpty || repeaterCountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a frequency in seconds')),
      );
      return;
    }

    final frequency = int.tryParse(frequencyText);
    repeaterCount = int.tryParse(repeaterCountText) ?? 3;
    if (frequency == null || frequency <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Invalid frequency. Enter a positive number.')),
      );
      return;
    }

    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }

    setState(() {
      _isSpeaking = true;
    });

    _announceTime(); // Announce immediately once
    _timer = Timer.periodic(Duration(minutes: frequency), (timer) {
      _announceTime();
    });
  }

  Future<void> _announceTime() async {
    final now = DateTime.now();
    final formattedTime = DateFormat('h:mm a').format(now); // e.g., 3:45 PM
    setState(() {
      // ignore: unnecessary_string_interpolations
      CurrentTime = '$formattedTime';
    });
    final message = "The current time is $formattedTime";
    for (var i = 0; i < repeaterCount; i++) {
      await flutterTts.speak(message);
      // Wait for speech to finish
      await flutterTts.awaitSpeakCompletion(true);
    }
  }

  void _stopAnnouncing() {
    _frequencyController.clear();
    _repeaterController.clear();
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    setState(() {
      _isSpeaking = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    flutterTts.stop();
    _frequencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Time Announcer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current Time: $CurrentTime',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _repeaterController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Repeater (Number Of Times)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _frequencyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Frequency (in minutes)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isSpeaking ? null : _startAnnouncing,
                  child: const Text('Start'),
                ),
                ElevatedButton(
                  onPressed: _isSpeaking ? _stopAnnouncing : null,
                  child: const Text('Stop'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
