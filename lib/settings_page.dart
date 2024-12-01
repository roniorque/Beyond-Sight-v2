import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double iouThreshold = 0.5;      // Default IOU threshold
  double confThreshold = 0.5;     // Default confidence threshold
  double classThreshold = 0.5;    // Default class threshold

  @override
  void initState() {
    super.initState();
    _loadThresholds(); // Load saved thresholds on startup
  }

  // Load saved threshold values
  Future<void> _loadThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      iouThreshold = prefs.getDouble('iouThreshold') ?? 0.5;
      confThreshold = prefs.getDouble('confThreshold') ?? 0.5;
      classThreshold = prefs.getDouble('classThreshold') ?? 0.5;
    });
  }

  // Save current threshold values
  Future<void> _saveThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('iouThreshold', iouThreshold);
    await prefs.setDouble('confThreshold', confThreshold);
    await prefs.setDouble('classThreshold', classThreshold);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thresholds saved successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Adjust Thresholds',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildSlider(
              label: 'IOU Threshold',
              value: iouThreshold,
              onChanged: (newValue) {
                setState(() {
                  iouThreshold = newValue;
                });
              },
            ),
            _buildSlider(
              label: 'Confidence Threshold',
              value: confThreshold,
              onChanged: (newValue) {
                setState(() {
                  confThreshold = newValue;
                });
              },
            ),
            _buildSlider(
              label: 'Class Threshold',
              value: classThreshold,
              onChanged: (newValue) {
                setState(() {
                  classThreshold = newValue;
                });
              },
            ),
            const SizedBox(height: 20), // Add space before the button
            ElevatedButton(
              onPressed: () async {
                await _saveThresholds(); // Save thresholds when button is clicked
                Navigator.pop(context); // Optionally return to the previous page
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${(value * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 16)),
        Slider(
          value: value,
          min: 0.0,
          max: 1.0,
          divisions: 100,
          label: '${(value * 100).toStringAsFixed(0)}%',
          onChanged: onChanged,
          activeColor: Colors.blueAccent,
          inactiveColor: Colors.grey,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
