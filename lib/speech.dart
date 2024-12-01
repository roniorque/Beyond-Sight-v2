import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechCommand extends StatefulWidget {
  final Function(String) onCommandRecognized;
  final Function(bool) onListeningStateChanged; // Notify parent when mic is toggled

  const SpeechCommand({
    super.key,
    required this.onCommandRecognized,
    required this.onListeningStateChanged, // Add this parameter
  });

  @override
  _SpeechCommandState createState() => _SpeechCommandState();
}

class _SpeechCommandState extends State<SpeechCommand> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _command = ''; // To store the recognized object from speech command

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  // Function to handle speech recognition and command processing
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() {
          _isListening = true;
        });
        widget.onListeningStateChanged(true); // Notify parent that mic is on
        _speech.listen(
          onResult: (val) => setState(() {
            _command = val.recognizedWords.toLowerCase(); // Convert speech to lowercase command
            if (_command.contains('find')) {  // If the command contains "find"
              _command = _command.replaceAll('find', '').trim();  // Remove 'find' and extract the object
              print('Command to find: $_command');
              widget.onCommandRecognized(_command); // Pass the command to object detection logic
            } else {
              print("Command doesn't contain 'find'");
              widget.onCommandRecognized(''); // If no valid command, don't recognize
            }
          }),
          listenFor: Duration(seconds: 5), // Increase listen time if needed
        );
      }
    } else {
      _stopListening();
    }
  }

  // Manually stop listening when necessary
  void _stopListening() {
    setState(() {
      _isListening = false;
      _speech.stop();
      widget.onListeningStateChanged(false); // Notify parent that mic is off
      widget.onCommandRecognized(''); // Notify parent to stop object detection
    });
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _listen,
      backgroundColor: _isListening ? Colors.redAccent : Colors.blueAccent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
      child: Icon(
        _isListening ? Icons.mic : Icons.mic_none,
        size: 30,
        color: Colors.white,
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}
