import 'package:flutter/material.dart';
import 'package:widget_recorder_plus/widget_recorder_plus.dart';
import 'package:open_file/open_file.dart';
import 'camera_recording_test.dart';
import 'new_features_demo.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Widget Recorder Plus',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Recorder Plus'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.video_library,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Widget Recorder Plus',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Record widgets as video, GIF, or screenshot',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              _DemoCard(
                icon: Icons.fiber_manual_record,
                title: 'Video Recording',
                description: 'Record widgets as MP4 video',
                color: Colors.red,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecordingDemo(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _DemoCard(
                icon: Icons.auto_awesome,
                title: 'New Features',
                description: 'Screenshot, GIF & Touch Visualization',
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NewFeaturesDemo(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _DemoCard(
                icon: Icons.camera_alt,
                title: 'Camera Test',
                description: 'Test camera recording',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CameraRecordingTest(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _DemoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $error')),
        );
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
      appBar: AppBar(title: const Text('Video Recording Demo')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              WidgetRecorder(
                controller: controller,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
