import 'package:flutter/material.dart';
import 'package:widget_recorder_plus/widget_recorder_plus.dart';

/// Example showing how to use a custom permission dialog
class CustomDialogExample extends StatefulWidget {
  const CustomDialogExample({super.key});

  @override
  State<CustomDialogExample> createState() => _CustomDialogExampleState();
}

class _CustomDialogExampleState extends State<CustomDialogExample> {
  late WidgetRecorderController controller;

  @override
  void initState() {
    super.initState();
    
    // Example with custom permission dialog
    controller = WidgetRecorderController(
      recordAudio: true,
      
      // Optional: Provide custom dialog
      permissionDeniedDialog: (context, openSettings) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.mic_off, color: Colors.orange[700]),
              const SizedBox(width: 10),
              const Text('Microphone Access'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We need microphone permission to record audio with your video.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Please enable it in Settings to continue.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                openSettings(); // Open app settings
                Navigator.of(context).pop(true);
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
      
      onComplete: (path) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Video saved: $path')),
        );
      },
      
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $error')),
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Dialog Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WidgetRecorder(
              controller: controller,
              child: Container(
                width: 200,
                height: 200,
                color: Colors.blue,
                child: const Center(
                  child: Text(
                    'Recording Area',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: controller.isRecording
                  ? null
                  : () => controller.start(), // Permission handled automatically
              child: const Text('Start Recording'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: controller.isRecording
                  ? () => controller.stop()
                  : null,
              child: const Text('Stop Recording'),
            ),
          ],
        ),
      ),
    );
  }
}
