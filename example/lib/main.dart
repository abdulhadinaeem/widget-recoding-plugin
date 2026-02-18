import 'package:flutter/material.dart';
import 'package:widget_recorder_plus/widget_recorder_plus.dart';
import 'package:open_file/open_file.dart';

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
  bool hasPermission = false;

  @override
  void initState() {
    super.initState();
    controller = WidgetRecorderController(
      recordAudio: true, 
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
    
    checkPermission();
  }

  Future<void> checkPermission() async {
    final hasPermission = await controller.hasPermission();
    setState(() {
      this.hasPermission = hasPermission;
    });
  }

  Future<void> requestPermission() async {
    final granted = await controller.requestPermission();
    setState(() {
      hasPermission = granted;
    });

    if (!granted) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'Microphone permission is required for audio recording. '
            'Please enable it in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                controller.openSettings();
                Navigator.pop(context);
              },
              child: const Text('Settings'),
            ),
          ],
        ),
      );
    }
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
                          // Request permission if not granted
                          if (!hasPermission) {
                            await requestPermission();
                            if (!hasPermission) {
                              setState(() => statusMessage = '❌ Microphone permission required');
                              return;
                            }
                          }
                          setState(() => statusMessage = '🔴 Recording...');
                          await controller.start();
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasPermission ? Icons.mic : Icons.mic_off,
                  color: hasPermission ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  hasPermission ? 'Audio enabled' : 'Audio disabled',
                  style: TextStyle(
                    fontSize: 14,
                    color: hasPermission ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              statusMessage,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
