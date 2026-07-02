import 'package:flutter/material.dart';
import 'package:widget_recorder_plus/widget_recorder_plus.dart';
import 'package:open_file/open_file.dart';

class NewFeaturesDemo extends StatefulWidget {
  const NewFeaturesDemo({super.key});

  @override
  State<NewFeaturesDemo> createState() => _NewFeaturesDemoState();
}

class _NewFeaturesDemoState extends State<NewFeaturesDemo>
    with SingleTickerProviderStateMixin {
  late WidgetRecorderController controller;
  late AnimationController animController;
  String statusMessage = 'Try the new features!';
  bool showTouchIndicators = false;
  GifQuality selectedQuality = GifQuality.medium;
  VideoQuality selectedVideoQuality = VideoQuality.medium;
  int countdownValue = 0;

  @override
  void initState() {
    super.initState();
    controller = WidgetRecorderController(
      showTouches: showTouchIndicators,
      touchConfig: const TouchVisualizationConfig(
        color: Colors.blue,
        size: 50,
        opacity: 0.6,
        showRipple: true,
      ),
      onComplete: (path) {
        setState(() => statusMessage = '✅ Saved: $path');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Saved: $path'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () async {
                await OpenFile.open(path);
              },
            ),
            duration: const Duration(seconds: 5),
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
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    animController.dispose();
    super.dispose();
  }

  Future<void> _captureScreenshot() async {
    setState(() => statusMessage = '📸 Capturing screenshot...');
    final path = await controller.captureScreenshot(
      format: ImageFormat.png,
      pixelRatio: 3.0,
    );
    if (path != null) {
      setState(() => statusMessage = '✅ Screenshot saved!');
    }
  }

  Future<void> _exportGif() async {
    setState(() => statusMessage = '🎬 Recording GIF...');
    await controller.exportAsGif(
      duration: const Duration(seconds: 3),
      quality: selectedQuality,
    );
  }
  
  Future<void> _recordVideoWithCountdown() async {
    controller.applyVideoQuality(selectedVideoQuality);
    setState(() {
      statusMessage = 'Starting in...';
      countdownValue = 3;
    });
    
    await controller.startWithCountdown(
      countdownSeconds: 3,
      onTick: (remaining) {
        setState(() {
          countdownValue = remaining;
          statusMessage = '⏳ Starting in $remaining...';
        });
      },
    );
    
    setState(() {
      statusMessage = '🔴 Recording with ${selectedVideoQuality.description}';
      countdownValue = 0;
    });
  }
  
  Future<void> _stopRecording() async {
    await controller.stop();
    setState(() => statusMessage = '⏹️ Recording stopped');
  }

  void _toggleTouchVisualization() {
    setState(() {
      showTouchIndicators = !showTouchIndicators;
    });
    
    // Recreate controller with new touch settings
    controller.dispose();
    controller = WidgetRecorderController(
      showTouches: showTouchIndicators,
      touchConfig: const TouchVisualizationConfig(
        color: Colors.blue,
        size: 50,
        opacity: 0.6,
        showRipple: true,
      ),
      onComplete: (path) {
        setState(() => statusMessage = '✅ Saved: $path');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Saved: $path'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () async {
                await OpenFile.open(path);
              },
            ),
            duration: const Duration(seconds: 5),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Features Demo'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Animated widget to capture
              Center(
                child: WidgetRecorder(
                  controller: controller,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.purple.shade400,
                          Colors.blue.shade400,
                          Colors.cyan.shade400,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: animController,
                      builder: (context, child) {
                        return Stack(
                          children: [
                            // Animated circles
                            Positioned(
                              left: 115 * animController.value,
                              top: 115 * animController.value,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 115 * animController.value,
                              bottom: 115 * animController.value,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            // Center text
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Widget Recorder',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    controller.isRecording
                                        ? '🔴 Recording'
                                        : 'Tap anywhere!',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Status message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Feature 1: Screenshot
              _FeatureSection(
                icon: Icons.camera_alt,
                title: 'Screenshot Capture',
                description: 'Capture high-quality PNG screenshots',
                color: Colors.green,
                child: ElevatedButton.icon(
                  onPressed: _captureScreenshot,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture Screenshot'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Feature 2: GIF Export
              _FeatureSection(
                icon: Icons.gif_box,
                title: 'GIF Export',
                description: 'Export animations as GIF files',
                color: Colors.orange,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Text('Quality: '),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SegmentedButton<GifQuality>(
                            segments: const [
                              ButtonSegment(
                                value: GifQuality.low,
                                label: Text('Low'),
                              ),
                              ButtonSegment(
                                value: GifQuality.medium,
                                label: Text('Medium'),
                              ),
                              ButtonSegment(
                                value: GifQuality.high,
                                label: Text('High'),
                              ),
                            ],
                            selected: {selectedQuality},
                            onSelectionChanged: (Set<GifQuality> newSelection) {
                              setState(() {
                                selectedQuality = newSelection.first;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: controller.isRecordingGif ? null : _exportGif,
                      icon: const Icon(Icons.gif_box),
                      label: Text(
                        controller.isRecordingGif
                            ? 'Recording GIF...'
                            : 'Export as GIF (3s)',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'FPS: ${selectedQuality.fps}, Colors: ${selectedQuality.colors}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // NEW Feature: Video Quality Presets & Countdown
              _FeatureSection(
                icon: Icons.high_quality,
                title: 'Video Quality & Countdown',
                description: 'Quality presets and countdown timer',
                color: Colors.purple,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Text('Quality: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<VideoQuality>(
                            value: selectedVideoQuality,
                            isExpanded: true,
                            items: VideoQuality.values.map((quality) {
                              return DropdownMenuItem(
                                value: quality,
                                child: Text(quality.description, style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => selectedVideoQuality = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (countdownValue > 0)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple),
                        ),
                        child: Center(
                          child: Text(
                            '$countdownValue',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ),
                      ),
                    if (countdownValue == 0) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: controller.isRecording ? null : _recordVideoWithCountdown,
                              icon: const Icon(Icons.fiber_manual_record),
                              label: const Text('Record with Countdown'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          if (controller.isRecording) ...[
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _stopRecording,
                              icon: const Icon(Icons.stop),
                              label: const Text('Stop'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '3-second countdown before recording starts',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Feature 3: Touch Visualization
              _FeatureSection(
                icon: Icons.touch_app,
                title: 'Touch Visualization',
                description: 'Show touch indicators during recording',
                color: Colors.blue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile(
                      value: showTouchIndicators,
                      onChanged: (value) => _toggleTouchVisualization(),
                      title: const Text('Enable Touch Indicators'),
                      subtitle: Text(
                        showTouchIndicators
                            ? 'Touch indicators are ON'
                            : 'Touch indicators are OFF',
                      ),
                      activeColor: Colors.blue,
                    ),
                    if (showTouchIndicators) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tap on the animated widget above to see touch indicators!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Widget child;

  const _FeatureSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
