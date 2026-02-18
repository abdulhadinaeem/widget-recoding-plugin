import 'package:flutter/material.dart';
import 'package:widget_recorder_plus/widget_recorder_plus.dart';
import 'package:open_file/open_file.dart';
import 'camera_recording_test.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Widget Recorder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const RecordingDemo(),
    );
  }
}

class RecordingDemo extends StatefulWidget {
  const RecordingDemo({super.key});

  @override
  State<RecordingDemo> createState() => _RecordingDemoState();
}

class _RecordingDemoState extends State<RecordingDemo>
    with SingleTickerProviderStateMixin {
  late WidgetRecorderController controller;
  late AnimationController animController;
  String? videoPath;
  String statusMessage = 'Ready to record';

  @override
  void initState() {
    super.initState();
    controller = WidgetRecorderController(
      recordAudio: true, // Permission handled automatically
      onComplete: (path) {
        setState(() {
          videoPath = path;
          statusMessage = '✅ Recording saved!';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Video saved: $path'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () async {
                await OpenFile.open(path);
              },
            ),
            duration: const Duration(seconds: 10),
          ),
        );
      },
      onError: (error) {
        setState(() => statusMessage = '❌ Error: $error');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $error')));
      },
    );

    animController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Widget Recorder Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Wrap widget to record
            WidgetRecorder(
              controller: controller,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: AnimatedBuilder(
                  animation: animController,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        Positioned(
                          left: 150 * animController.value,
                          top: 150 * animController.value,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 150 * animController.value,
                          bottom: 150 * animController.value,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            controller.isRecording ? '🔴 REC' : '⏸️ Ready',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: controller.isRecording
                      ? null
                      : () async {
                          setState(() => statusMessage = '🔴 Recording...');
                          await controller.start(); // Permission handled automatically
                        },
                  icon: const Icon(Icons.fiber_manual_record),
                  label: const Text('Start'),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: controller.isRecording
                      ? () async {
                          await controller.stop();
                          setState(() => statusMessage = '⏹️ Stopped');
                        }
                      : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              statusMessage,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CameraRecordingTest(),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Test Camera Recording'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            if (videoPath != null) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Video: $videoPath',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
