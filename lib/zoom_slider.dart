import 'package:flutter/material.dart';

class ZoomSlider extends StatelessWidget {
  final double currentZoomLevel;
  final double maxZoomLevel;
  final ValueChanged<double> onZoomChanged;

  const ZoomSlider({
    Key? key,
    required this.currentZoomLevel,
    required this.maxZoomLevel,
    required this.onZoomChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: Colors.blueAccent,
        inactiveTrackColor: Colors.grey,
        trackHeight: 4.0,
        thumbColor: Colors.blueAccent,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
        overlayColor: Colors.blueAccent.withOpacity(0.2),
      ),
      child: Slider(
        value: currentZoomLevel,
        min: 1.0,
        max: maxZoomLevel,
        divisions: (maxZoomLevel - 1).round(),
        label: 'Zoom: ${currentZoomLevel.toStringAsFixed(1)}x',
        onChanged: onZoomChanged,
      ),
    );
  }
}
