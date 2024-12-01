import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class FlashButton extends StatefulWidget {
  final CameraController controller;

  const FlashButton({Key? key, required this.controller}) : super(key: key);

  @override
  _FlashButtonState createState() => _FlashButtonState();
}

class _FlashButtonState extends State<FlashButton> {
  bool _isFlashOn = false;

  Future<void> _toggleFlash() async {
    if (widget.controller.value.flashMode == FlashMode.off) {
      await widget.controller.setFlashMode(FlashMode.torch);
      setState(() {
        _isFlashOn = true;
      });
    } else {
      await widget.controller.setFlashMode(FlashMode.off);
      setState(() {
        _isFlashOn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isFlashOn ? Icons.flash_on : Icons.flash_off,
        color: _isFlashOn ? Colors.yellow : Colors.white,
      ),
      onPressed: _toggleFlash,
    );
  }
}
