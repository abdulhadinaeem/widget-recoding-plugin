# widget_recorder_plus

[![pub package](https://img.shields.io/pub/v/widget_recorder_plus.svg)](https://pub.dev/packages/widget_recorder_plus)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.7.0+-blue.svg)](https://flutter.dev)

A powerful Flutter package to record any widget as a high-quality MP4 video. Perfect for creating tutorials, demos, animations, and exporting dynamic content with just a few lines of code.

## Demo

<p align="center">
  <img src="https://raw.githubusercontent.com/abdulhadinaeem/widget-recoding-plugin/master/example_video%20(1).gif" alt="Widget Recorder Demo" width="300"/>
</p>


## Features

- Record Any Widget - Capture any Flutter widget as MP4 video
- Audio Recording - Optional microphone audio capture (iOS & Android)
- Automatic Permissions - Built-in permission handling with customizable dialogs
- Simple API - Just 3 lines to integrate
- Configurable FPS - 15-60 FPS (default 60)
- Cross-Platform - Android (API 21+) and iOS (13+)
- Auto File Management - No path management needed
- Built-in Callbacks - Success and error handling
- High Quality - Native H.264 codec with 10 Mbps/megapixel bitrate
- Smooth Encoding - Optimized for performance
- Proper Finalization - Ensures video files are always valid

## Platform Support

| Platform | Min Version | Status |
|----------|-------------|--------|
| Android  | API 21 (5.0) | Fully Supported |
| iOS      | 13.0        | Fully Supported |
| Web      | -           | Not Supported |
| macOS    | -           | Not Supported |
| Windows  | -           | Not Supported |
| Linux    | -           | Not Supported |

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  widget_recorder_plus: ^1.0.2
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Import the Package

```dart
import 'package:widget_recorder_plus/widget_recorder_plus.dart';
```

### 2. Create a Controller

```dart
final controller = WidgetRecorderController(
  recordAudio: true, // Enable audio recording (permission handled automatically!)
  onComplete: (path) => print('Video saved: $path'),
  onError: (error) => print('Error: $error'),
);
```

### 3. Wrap Your Widget

```dart
WidgetRecorder(
  controller: controller,
  child: YourWidget(),
)
```

### 4. Start Recording

```dart
// Start recording
await controller.start();

// Stop recording (returns file path)
final videoPath = await controller.stop();
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:widget_recorder/widget_recorder.dart';
import 'package:open_file/open_file.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late WidgetRecorderController controller;
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    controller = WidgetRecorderController(
      onComplete: (path) {
        setState(() => isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video saved: $path'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFile.open(path),
            ),
          ),
        );
      },
      onError: (error) {
        setState(() => isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> toggleRecording() async {
    if (isRecording) {
      await controller.stop();
    } else {
      setState(() => isRecording = true);
      await controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'Recording this!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: toggleRecording,
                icon: Icon(isRecording ? Icons.stop : Icons.videocam),
                label: Text(isRecording ? 'Stop Recording' : 'Start Recording'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## API Reference

### WidgetRecorderController

Main controller for managing widget recording.

#### Constructor

```dart
WidgetRecorderController({
  Function(String path)? onComplete,
  Function(String error)? onError,
  bool recordAudio = false,
  Widget Function(BuildContext context, VoidCallback openSettings)? permissionDeniedDialog,
})
```

**Parameters:**
- `onComplete` - Called when recording finishes with the video file path
- `onError` - Called when an error occurs during recording
- `recordAudio` - Enable microphone audio recording (default: false, permission handled automatically)
- `permissionDeniedDialog` - Optional custom dialog when permission is denied

#### Properties

```dart
// Set frames per second (15-60, default: 60)
controller.fps = 30;

// Check if currently recording
bool isRecording = controller.isRecording;
```

#### Methods

```dart
// Start recording (auto-generates file path in temp directory)
// Permission is handled automatically if recordAudio is true
await controller.start();

// Stop recording (returns file path)
final path = await controller.stop();

// Manual permission control (optional - not needed with automatic handling)
bool hasPermission = await controller.hasPermission();
bool granted = await controller.requestPermission();
await controller.openSettings();

// Clean up resources
controller.dispose();
```

### WidgetRecorder Widget

Wrapper widget that enables recording for its child.

```dart
WidgetRecorder(
  controller: controller,  // Required
  child: MyWidget(),       // Required
)
```

## Usage Examples

### Automatic Permission Handling

When `recordAudio: true`, permissions are handled automatically - no manual checks needed!

```dart
final controller = WidgetRecorderController(
  recordAudio: true, // Permission handled automatically
  onComplete: (path) => print('Saved: $path'),
  onError: (error) => print('Error: $error'),
);

// Just call start - permission dialog shows automatically if needed
await controller.start();
```

**Custom Permission Dialog (Optional):**

```dart
final controller = WidgetRecorderController(
  recordAudio: true,
  permissionDeniedDialog: (context, openSettings) {
    return AlertDialog(
      title: const Text('Microphone Access Required'),
      content: const Text('Please enable microphone in Settings.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            openSettings(); // Opens app settings
            Navigator.pop(context, true);
          },
          child: const Text('Open Settings'),
        ),
      ],
    );
  },
);
```

See [AUTOMATIC_PERMISSIONS.md](AUTOMATIC_PERMISSIONS.md) for detailed documentation.

### Recording with Audio

```dart
class AudioRecordingDemo extends StatefulWidget {
  @override
  State<AudioRecordingDemo> createState() => _AudioRecordingDemoState();
}

class _AudioRecordingDemoState extends State<AudioRecordingDemo> {
  late WidgetRecorderController controller;

  @override
  void initState() {
    super.initState();
    controller = WidgetRecorderController(
      recordAudio: true, // Enable audio recording (permission handled automatically!)
      onComplete: (path) {
        print('Video with audio saved: $path');
      },
    );
  }

  Future<void> startRecordingWithAudio() async {
    // Just call start - permission is handled automatically!
    await controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return WidgetRecorder(
      controller: controller,
      child: YourWidget(),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

### Recording Animations

```dart
class AnimatedDemo extends StatefulWidget {
  @override
  State<AnimatedDemo> createState() => _AnimatedDemoState();
}

class _AnimatedDemoState extends State<AnimatedDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController animController;
  late WidgetRecorderController recController;

  @override
  void initState() {
    super.initState();
    recController = WidgetRecorderController();
    animController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  Future<void> recordAnimation() async {
    await recController.start();
    await animController.forward();
    await recController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return WidgetRecorder(
      controller: recController,
      child: AnimatedBuilder(
        animation: animController,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.5 + (animController.value * 0.5),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    animController.dispose();
    recController.dispose();
    super.dispose();
  }
}
```

### Adjusting Video Quality

```dart
// Lower FPS for smaller files (good for sharing)
controller.fps = 15;

// Medium quality (balanced)
controller.fps = 30;

// High quality (smooth animations)
controller.fps = 60;
```

### Record for Specific Duration

```dart
Future<void> recordForSeconds(int seconds) async {
  await controller.start();
  await Future.delayed(Duration(seconds: seconds));
  await controller.stop();
}
```

### Toggle Recording

```dart
Future<void> toggleRecording() async {
  if (controller.isRecording) {
    await controller.stop();
  } else {
    await controller.start();
  }
}
```

## Permissions

### Android

Add to `android/app/src/main/AndroidManifest.xml` (only if saving to external storage):

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
```

Note: By default, videos are saved to app-specific directories (no permission needed).

### iOS

Add to `ios/Runner/Info.plist` (only if saving to Photos library):

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to save recorded videos</string>
```

Note: By default, videos are saved to app-specific directories (no permission needed).

## Performance Tips

| Tip | Benefit |
|-----|---------|
| Use FPS 15-24 | Smaller files, less CPU usage |
| Keep widget size <= 1080p | Better performance |
| Close background apps | More resources available |
| Test on real devices | Accurate performance metrics |
| Dispose controller | Prevents memory leaks |

## Troubleshooting

### Empty or corrupted video file
Solution: Always call `controller.stop()` to properly finalize the video. The file is only valid after stop completes.

### Widget not captured
Solution: Ensure the widget is visible on screen during recording. The widget must be rendered to be captured.

### Recording is laggy or drops frames
Solution: Reduce FPS: `controller.fps = 15` or reduce widget complexity.

### "Unsupported media" error when opening video
Solution: Ensure recording completed successfully. Wait for `onComplete` callback before accessing the file.

### Permission denied error
Solution: Check AndroidManifest.xml and Info.plist configurations. Ensure app has necessary permissions.

### Build fails on Android
Solution: Ensure Kotlin support is enabled. Update Android Gradle plugin to 7.0+.

### Build fails on iOS
Solution: Ensure Swift support is enabled. Update iOS deployment target to 13.0+.

## Limitations

- Audio is not captured (video only)
- Widget must be visible on screen during recording
- Platform views (WebView, MapView) may not capture correctly
- Not suitable for real-time streaming
- Maximum recommended widget size: 1920x1080

## How It Works

1. Dart Layer - Uses RepaintBoundary to capture widget frames as RGBA pixel data
2. Frame Conversion - Converts RGBA to YUV420 (Android) or BGRA (iOS)
3. Native Encoding - Uses MediaCodec (Android) or AVAssetWriter (iOS) for H.264 encoding
4. MP4 Output - Creates valid MP4 video file with proper timestamps and finalization

## Video Specifications

| Property | Value |
|----------|-------|
| Format | MP4 (MPEG-4) |
| Codec | H.264 (AVC) |
| Container | MP4 |
| Bitrate | 10 Mbps per megapixel |
| FPS | Configurable (15-60, default 60) |
| Audio | Not supported |
| Color Space | YUV420 (Android), BGRA (iOS) |

## App Store Compliance

- Google Play Store - Compliant (in-app widget recording, not screen capture)
- Apple App Store - Compliant (internal rendering, not screen recording)

Always include appropriate privacy policy disclosures about video recording features in your app.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

- Check the example app for working code
- Report issues on GitHub
- Discuss on pub.dev

## Changelog

See CHANGELOG.md for version history and updates.

---

Made with love for Flutter developers
