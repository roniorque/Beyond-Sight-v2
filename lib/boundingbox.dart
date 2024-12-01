import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:ui' as ui;

class BoundingBoxPainter extends CustomPainter {
  final List<dynamic> detections;
  final CameraController cameraController;
  final String selectedObject;
  bool _lookingForObjectAudioTriggered = false;
  bool _obstacleWarningAudioTriggered = false;

  BoundingBoxPainter(this.detections, this.cameraController, {this.selectedObject = ''});

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint selectedPaint = Paint()
      ..color = Colors.green  // Green for selected object or all objects in DetectAllObjectsPage
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final Paint obstaclePaint = Paint()
      ..color = Colors.red  // Red for obstacles
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final previewSize = cameraController.value.previewSize!;
    final double scaleX = size.width / previewSize.height;
    final double scaleY = size.height / previewSize.width;

    bool shouldShowObstacleBoundingBox = false;

    for (var detection in detections) {
      final box = detection['box'];
      if (box.length == 5) {
        final left = box[0] * scaleX;
        final top = box[1] * scaleY;
        final right = box[2] * scaleX;
        final bottom = box[3] * scaleY;

        // If 'selectedObject' is empty, consider all objects as 'selected' in DetectAllObjectsPage
        final isSelected = selectedObject.isEmpty || detection['tag'].toLowerCase() == selectedObject.toLowerCase();
        final isObstacle = !isSelected;

        if (isSelected && !_lookingForObjectAudioTriggered) {
          _triggerLookingForObjectAudio();
        }

        if (isObstacle) {
          shouldShowObstacleBoundingBox = true;
          _triggerObstacleWarning();
        }

        // Draw the bounding box and text
        if (isSelected) {
          canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), selectedPaint);
        } else if (shouldShowObstacleBoundingBox) {
          canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), obstaclePaint);
        }

        final textPainter = TextPainter(
          text: TextSpan(
            text: '${(box[4] * 100).toInt()}% - ${detection['tag']}',
            style: TextStyle(color: isSelected ? Colors.green : Colors.red, fontSize: 16),
          ),
          textDirection: ui.TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(canvas, Offset(left, top - 20));
      }
    }

    if (shouldShowObstacleBoundingBox) {
      print('Obstacle Detected.');
    }
  }

  void _triggerLookingForObjectAudio() {
    if (!_lookingForObjectAudioTriggered) {
      _lookingForObjectAudioTriggered = true;
      print('Looking for $selectedObject.');
    }
  }

  void _triggerObstacleWarning() {
    if (!_obstacleWarningAudioTriggered) {
      _obstacleWarningAudioTriggered = true;
      print('Obstacle detected. Triggering warning.');
      Future.delayed(Duration(seconds: 3), () {
        _obstacleWarningAudioTriggered = false;
      });
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
