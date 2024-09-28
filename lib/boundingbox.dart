import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:ui' as ui;

class BoundingBoxPainter extends CustomPainter {
  final List<dynamic> detections;
  final CameraController cameraController;
  final String latency;

  BoundingBoxPainter(this.detections, this.cameraController, this.latency);

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final paint = Paint()
      ..color = Colors.red // High contrast color for bounding box
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0; // Increase stroke width for visibility

    // Get the camera preview size and the size of the canvas where we draw
    final previewSize = cameraController.value.previewSize!;
    final double scaleX = size.width / previewSize.height;
    final double scaleY = size.height / previewSize.width;

    for (var detection in detections) {
      final box = detection['box']; // Assuming this is [left, top, right, bottom, confidence]
      if (box.length == 5) { // Ensure box format is correct
        // Scale the bounding box coordinates to fit the screen
        final left = box[0] * scaleX;
        final top = box[1] * scaleY;
        final right = box[2] * scaleX;
        final bottom = box[3] * scaleY;

        // Draw rectangle using the scaled coordinates
        canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);

        // Draw the confidence text above the bounding box
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${(box[4] * 100).toStringAsFixed(2)}% - ${detection['tag']}',
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
          textDirection: ui.TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(canvas, Offset(left, top - 20)); // Adjust the position as needed
      }
    }

    // Draw latency text on the screen
    final latencyTextPainter = TextPainter(
      text: TextSpan(
        text: 'Latency: $latency',
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    latencyTextPainter.layout();
    latencyTextPainter.paint(canvas, const Offset(16, 16)); // Position the latency text
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint for new detections
  }
}
