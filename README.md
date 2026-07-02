# widget_recorder_plus

[![pub package](https://img.shields.io/pub/v/widget_recorder_plus.svg)](https://pub.dev/packages/widget_recorder_plus)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.7.0+-blue.svg)](https://flutter.dev)

A powerful Flutter package to record any widget as MP4 video, animated GIF, or high-quality screenshot. Features touch visualization for tutorials, automatic permission handling, and simple API. Perfect for creating demos, tutorials, and documentation.

## Demo

<p align="center">
  <img src="https://raw.githubusercontent.com/abdulhadinaeem/widget-recoding-plugin/master/example_video%20(1).gif" alt="Widget Recorder Demo" width="300"/>
</p>


## ✨ Features

### 🎥 Video Recording
- **MP4 Video Export** - High-quality H.264 video codec with optimized bitrate
- **Audio Recording** - Optional microphone audio capture (iOS & Android)
- **Automatic Permissions** - Built-in permission handling with customizable dialogs
- **Video Quality Presets** - Low (15 FPS, 2 Mbps), Medium (30 FPS, 5 Mbps), High (60 FPS, 10 Mbps) (NEW v1.1.0)
- **Countdown Timer** - 3-2-1 countdown before recording starts (NEW v1.1.0)
- **Custom Save Path** - Save to custom directories (NEW v1.1.0)
- **Configurable FPS** - 15-60 FPS (default 60)
- **Proper Finalization** - Ensures video files are always valid

### 📸 Screenshot Capture (NEW v1.1.0)
- **High-Quality Screenshots** - PNG/JPG export with configurable resolution
- **Retina Support** - Adjustable pixel ratio for ultra-high-res captures
- **Instant Capture** - Single-frame screenshot with one method call

### 🎞️ GIF Export (NEW v1.1.0)
- **Animated GIFs** - Export widgets as shareable GIF files
- **Quality Presets** - Low, Medium, High (10-24 FPS, 64-256 colors)
- **Auto or Manual** - Timed recording or manual start/stop control
- **Optimized Encoding** - Color quantization for smaller file sizes

### 👆 Touch Visualization (NEW v1.1.0)
- **Touch Indicators** - Show touch points during recording
- **Ripple Effects** - Animated ripples on tap with customizable colors
- **Fully Customizable** - Size, color, opacity, and animation duration
- **Tutorial Perfect** - Ideal for app demonstrations and user guides

### 🛠️ General Features
- **Simple API** - Just 3 lines to integrate
- **Cross-Platform** - Android (API 21+) and iOS (13+)
- **Auto File Management** - No path management needed
- **Built-in Callbacks** - Success and error handling
- **Smooth Encoding** - Optimized for performance

## Platform Support

| Platform | Min Version | Status |
|----------|-------------|--------|
| Android  | API 21 (5.0) | ✅ Fully Supported |
| iOS      | 13.0        | ✅ Fully Supported |
| Web      | -           | ❌ Not Supported |
| macOS    | -           | ❌ Not Supported |
| Windows  | -           | ❌ Not Supported |
| Linux    | -           | ❌ Not Supported |

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  widget_recorder_plus: ^1.1.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Video Recording

### 1. Import the Package

```dart
import 'package:widget_recorder_plus/widget_recorder_plus.dart';
```

### 2. Create a Controller

```dart
final controller = WidgetRecorderController(
  recordAudio: true, // Enable audio recording (permission handled automatically!)
  customSavePath: '/path/to/save/directory', // Optional: custom save location
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

**Basic:**
```dart
// Start recording immediately
await controller.start();

// Stop recording (returns file path)
final videoPath = await controller.stop();
```

**With Countdown (NEW v1.1.0):**
```dart
// Start with 3-second countdown
await controller.startWithCountdown(
  countdownSeconds: 3,
  onTick: (remaining) => print('Starting in $remaining...'),
);
```

**With Quality Preset (NEW v1.1.0):**
```dart
// Apply quality preset before recording
controller.applyVideoQuality(VideoQuality.high); // 60 FPS, 10 Mbps
await controller.start();
```

---

## 🎯 Video Quality Presets (NEW v1.1.0)

Choose from predefined quality presets for optimal balance between file size and quality:

```dart
final controller = WidgetRecorderController();

// Apply quality preset
controller.applyVideoQuality(VideoQuality.low);    // 15 FPS, 2 Mbps
controller.applyVideoQuality(VideoQuality.medium); // 30 FPS, 5 Mbps (recommended)
controller.applyVideoQuality(VideoQuality.high);   // 60 FPS, 10 Mbps

// Then start recording
await controller.start();
```

### Video Quality Comparison

| Preset | FPS | Bitrate | File Size* | Use Case |
|--------|-----|---------|------------|----------|
| `VideoQuality.low` | 15 | 2 Mbps | ~15 MB/min | Quick sharing, small file size |
| `VideoQuality.medium` | 30 | 5 Mbps | ~38 MB/min | Balanced quality & size |
| `VideoQuality.high` | 60 | 10 Mbps | ~75 MB/min | Best quality, smooth motion |

*Approximate file sizes for 720p resolution

---

## ⏱️ Countdown Timer (NEW v1.1.0)

Give yourself time to prepare before recording starts:

### Basic Countdown

```dart
// Start with 3-second countdown
await controller.startWithCountdown(
  countdownSeconds: 3,
  onTick: (remaining) {
    print('Starting in $remaining...');
  },
);
```

### Custom Countdown UI

```dart
int countdownValue = 0;

await controller.startWithCountdown(
  countdownSeconds: 5,
  onTick: (remaining) {
    setState(() {
      countdownValue = remaining;
    });
  },
);

// Display countdownValue in your UI
Text('Recording in: $countdownValue', style: TextStyle(fontSize: 48));
```

### Use Cases
- **Hands-free recording** - Get ready without rushing
- **Self-recording** - Position yourself before capture starts
- **Professional videos** - Smooth start without fumbling
- **Live demos** - Time to prepare your demonstration

---

## 📁 Custom Save Path (NEW v1.1.0)

Save recordings to custom locations instead of temp directory:

```dart
// Save to documents directory
final controller = WidgetRecorderController(
  customSavePath: '/path/to/your/directory',
);

// Or use path_provider for platform directories
import 'package:path_provider/path_provider.dart';

final appDocDir = await getApplicationDocumentsDirectory();
final controller = WidgetRecorderController(
  customSavePath: '${appDocDir.path}/my_recordings',
);

// All recordings (video, screenshot, GIF) will save to custom path
await controller.start();
await controller.captureScreenshot();
await controller.exportAsGif();
```

### Benefits
- **Organized storage** - Keep recordings in dedicated folders
- **Easy access** - Find files quickly
- **Gallery integration** - Save to photo library directory
- **App-specific storage** - Isolate from system temp files

---

## 📸 Screenshot Capture

Capture high-quality screenshots of any widget instantly:

```dart
// Create controller
final controller = WidgetRecorderController();

// Wrap your widget
WidgetRecorder(
  controller: controller,
  child: MyWidget(),
)

// Capture screenshot (PNG format, 3x retina resolution)
final screenshotPath = await controller.captureScreenshot(
  format: ImageFormat.png,
  pixelRatio: 3.0,
);

print('Screenshot saved: $screenshotPath');
```

### Screenshot Options

```dart
await controller.captureScreenshot(
  format: ImageFormat.png,  // ImageFormat.png or ImageFormat.jpg
  pixelRatio: 3.0,          // 1.0 = normal, 2.0 = retina, 3.0 = ultra-high-res
  quality: 100,             // 1-100 (for JPG only, ignored for PNG)
);
```

---

## 🎞️ GIF Export

Export widgets as animated GIFs - perfect for documentation and sharing:

### Automatic Timed Recording

```dart
final controller = WidgetRecorderController();

// Record for 3 seconds and export as GIF
final gifPath = await controller.exportAsGif(
  duration: Duration(seconds: 3),
  quality: GifQuality.medium,
);

print('GIF saved: $gifPath');
```

### Manual Control

```dart
// Start GIF recording
await controller.startGifRecording(quality: GifQuality.high);

// ... user interacts with widget ...

// Stop and export
final gifPath = await controller.stopGifRecording(quality: GifQuality.high);
```

### GIF Quality Presets

| Preset | FPS | Colors | File Size | Use Case |
|--------|-----|--------|-----------|----------|
| `GifQuality.low` | 10 | 64 | Smallest | Quick demos, small file sharing |
| `GifQuality.medium` | 15 | 128 | Balanced | General purpose, documentation |
| `GifQuality.high` | 24 | 256 | Largest | Smooth animations, high quality |

```dart
// Example with different qualities
await controller.exportAsGif(
  duration: Duration(seconds: 5),
  quality: GifQuality.high,  // Best quality
);
```

---

## 👆 Touch Visualization

Show touch indicators during recording - perfect for tutorials and app demos:

### Basic Usage

```dart
final controller = WidgetRecorderController(
  showTouches: true,  // Enable touch visualization
  touchConfig: TouchVisualizationConfig(
    color: Colors.blue,
    size: 50,
    opacity: 0.6,
    showRipple: true,
  ),
);
```

### Full Configuration

```dart
final controller = WidgetRecorderController(
  showTouches: true,
  touchConfig: TouchVisualizationConfig(
    color: Colors.blue,                           // Touch indicator color
    size: 50.0,                                   // Indicator size in pixels
    opacity: 0.6,                                 // 0.0 to 1.0
    showRipple: true,                             // Animated ripple effect
    rippleDuration: Duration(milliseconds: 300),  // Ripple animation duration
  ),
);
```

### Use Cases

- **App Tutorials** - Show users where to tap
- **Feature Demos** - Highlight interactive elements
- **Bug Reports** - Show exact tap locations
- **Marketing Videos** - Professional-looking demonstrations

---

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:widget_recorder_plus/widget_recorder_plus.dart';
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
      showTouches: true,  // NEW: Enable touch visualization
      onComplete: (path) {
        setState(() => isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: $path'),
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
  
  // NEW: Capture screenshot
  Future<void> captureScreenshot() async {
    final path = await controller.captureScreenshot();
    print('Screenshot: $path');
  }
  
  // NEW: Export GIF
  Future<void> exportGif() async {
    await controller.exportAsGif(
      duration: Duration(seconds: 3),
      quality: GifQuality.medium,
    );
  }  }

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

Main controller for managing widget recording, screenshot capture, and GIF export.

#### Constructor

```dart
WidgetRecorderController({
  Function(String path)? onComplete,
  Function(String error)? onError,
  bool recordAudio = false,
  Widget Function(BuildContext context, VoidCallback openSettings)? permissionDeniedDialog,
  bool showTouches = false,  // NEW v1.1.0
  TouchVisualizationConfig touchConfig = const TouchVisualizationConfig(),  // NEW v1.1.0
  String? customSavePath,  // NEW v1.1.0
})
```

**Parameters:**
- `onComplete` - Called when recording/export finishes with the file path
- `onError` - Called when an error occurs
- `recordAudio` - Enable microphone audio recording (default: false)
- `permissionDeniedDialog` - Optional custom dialog when permission is denied
- `showTouches` - Enable touch visualization (default: false) **NEW v1.1.0**
- `touchConfig` - Touch indicator configuration **NEW v1.1.0**
- `customSavePath` - Custom directory for saving files (optional) **NEW v1.1.0**

#### Properties

```dart
// Set frames per second for video recording (15-60, default: 60)
controller.fps = 30;

// Apply video quality preset (NEW v1.1.0)
controller.applyVideoQuality(VideoQuality.medium);

// Check if currently recording video or GIF
bool isRecording = controller.isRecording;

// Check if currently recording GIF specifically
bool isRecordingGif = controller.isRecordingGif;  // NEW v1.1.0
```

#### Video Recording Methods

```dart
// Start video recording (auto-generates file path)
await controller.start();

// Start with countdown (NEW v1.1.0)
await controller.startWithCountdown(
  countdownSeconds: 3,
  onTick: (remaining) => print('Starting in $remaining'),
);

// Start with custom countdown duration (NEW v1.1.0)
await controller.start(
  countdown: Duration(seconds: 5),
  onTick: (remaining) => print('$remaining'),
);

// Stop video recording (returns file path)
final path = await controller.stop();
```

#### Screenshot Methods (NEW v1.1.0)

```dart
// Capture high-quality screenshot
final screenshotPath = await controller.captureScreenshot(
  format: ImageFormat.png,  // ImageFormat.png or ImageFormat.jpg
  quality: 100,             // 1-100 (for JPG only)
  pixelRatio: 3.0,          // Resolution multiplier (1.0 = normal, 3.0 = retina)
);
```

#### GIF Export Methods (NEW v1.1.0)

```dart
// Automatic timed GIF recording
final gifPath = await controller.exportAsGif(
  duration: Duration(seconds: 3),
  quality: GifQuality.medium,
);

// Manual GIF recording (start)
await controller.startGifRecording(
  quality: GifQuality.medium,
);

// Manual GIF recording (stop and export)
final gifPath = await controller.stopGifRecording(
  quality: GifQuality.medium,
);
```

#### Permission Methods

```dart
// Manual permission control (optional - not needed with automatic handling)
bool hasPermission = await controller.hasPermission();
bool granted = await controller.requestPermission();
await controller.openSettings();
```

#### Cleanup

```dart
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

### TouchVisualizationConfig (NEW v1.1.0)

Configuration for touch visualization during recording.

```dart
const TouchVisualizationConfig({
  Color color = Colors.blue,
  double size = 50.0,
  double opacity = 0.6,
  bool showRipple = true,
  Duration rippleDuration = const Duration(milliseconds: 300),
})
```

**Parameters:**
- `color` - Touch indicator color
- `size` - Touch indicator size in pixels
- `opacity` - Touch indicator opacity (0.0 to 1.0)
- `showRipple` - Enable ripple animation effect
- `rippleDuration` - Duration of ripple animation

### ImageFormat Enum (NEW v1.1.0)

```dart
enum ImageFormat {
  png,  // PNG format (lossless, larger file size)
  jpg,  // JPG format (lossy, smaller file size)
}
```

### VideoQuality Enum (NEW v1.1.0)

```dart
enum VideoQuality {
  low,     // 15 FPS, 2 Mbps
  medium,  // 30 FPS, 5 Mbps (recommended)
  high,    // 60 FPS, 10 Mbps
}
```

**Properties:**
```dart
VideoQuality.medium.fps         // 30
VideoQuality.medium.bitrate     // 5000000
VideoQuality.medium.description // "Medium (30 FPS, 5 Mbps) - Balanced"
```

```dart
enum GifQuality {
  low,     // 10 FPS, 64 colors
  medium,  // 15 FPS, 128 colors (recommended)
  high,    // 24 FPS, 256 colors
}
```

**Properties:**
```dart
GifQuality.medium.fps      // 15
GifQuality.medium.colors   // 128
```

## Usage Examples

### Screenshot for App Store

```dart
class AppStoreScreenshots extends StatelessWidget {
  final controller = WidgetRecorderController();

  Future<void> captureForAppStore() async {
    // Ultra-high resolution for App Store
    final path = await controller.captureScreenshot(
      format: ImageFormat.png,
      pixelRatio: 3.0,  // Retina display quality
    );
    // Upload to App Store Connect
  }

  @override
  Widget build(BuildContext context) {
    return WidgetRecorder(
      controller: controller,
      child: MyAppScreenContent(),
    );
  }
}
```

### GIF for Documentation

```dart
class DocumentationGifs extends StatelessWidget {
  final controller = WidgetRecorderController();

  Future<void> createDocGif() async {
    // Medium quality for README files
    await controller.exportAsGif(
      duration: Duration(seconds: 5),
      quality: GifQuality.medium,
    );
    // Add to repository
  }

  @override
  Widget build(BuildContext context) {
    return WidgetRecorder(
      controller: controller,
      child: AnimatedFeatureDemo(),
    );
  }
}
```

### Tutorial Video with Touch Indicators

```dart
class TutorialRecorder extends StatefulWidget {
  @override
  State<TutorialRecorder> createState() => _TutorialRecorderState();
}

class _TutorialRecorderState extends State<TutorialRecorder> {
  late WidgetRecorderController controller;

  @override
  void initState() {
    super.initState();
    controller = WidgetRecorderController(
      recordAudio: true,  // Record voice narration
      showTouches: true,  // Show where user taps
      touchConfig: TouchVisualizationConfig(
        color: Colors.blue,
        size: 60,
        opacity: 0.7,
        showRipple: true,
      ),
    );
  }

  Future<void> recordTutorial() async {
    await controller.start();
    // User demonstrates the feature
    await Future.delayed(Duration(seconds: 10));
    await controller.stop();
  }

  @override
  Widget build(BuildContext context) {
    return WidgetRecorder(
      controller: controller,
      child: AppInterface(),
    );
  }
}
```

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
  
  // NEW: Export animation as GIF
  Future<void> exportAnimationAsGif() async {
    await recController.exportAsGif(
      duration: Duration(seconds: 2),
      quality: GifQuality.high,
    );
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

- Audio capture is supported for video recording only (not for GIF export)
- Widget must be visible on screen during recording
- Platform views (WebView, MapView) may not capture correctly
- Not suitable for real-time streaming
- Maximum recommended widget size: 1920x1080
- GIF file sizes can be large for long recordings at high quality

## How It Works

1. Dart Layer - Uses RepaintBoundary to capture widget frames as RGBA pixel data
2. Frame Conversion - Converts RGBA to YUV420 (Android) or BGRA (iOS)
3. Native Encoding - Uses MediaCodec (Android) or AVAssetWriter (iOS) for H.264 encoding
4. MP4 Output - Creates valid MP4 video file with proper timestamps and finalization

## Output Specifications

### Video (MP4)

| Property | Value |
|----------|-------|
| Format | MP4 (MPEG-4) |
| Codec | H.264 (AVC) |
| Container | MP4 |
| Bitrate | 10 Mbps per megapixel |
| FPS | Configurable (15-60, default 60) |
| Audio | AAC (optional, 128kbps stereo) |
| Color Space | YUV420 (Android), BGRA (iOS) |

### Screenshot (NEW v1.1.0)

| Property | Value |
|----------|-------|
| Format | PNG (lossless) or JPG (lossy) |
| Resolution | Configurable via pixelRatio |
| Default Quality | 3x device resolution (retina) |
| Color Depth | 32-bit RGBA |
| Compression | PNG: lossless, JPG: configurable 1-100 |

### GIF (NEW v1.1.0)

| Preset | FPS | Colors | Typical Size | Best For |
|--------|-----|--------|--------------|----------|
| Low | 10 | 64 | ~500KB/sec | Quick sharing, small demos |
| Medium | 15 | 128 | ~1MB/sec | Documentation, README files |
| High | 24 | 256 | ~2MB/sec | Smooth animations, presentations |

*File sizes are approximate and vary based on content complexity*

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

### Version 1.1.0 (Latest)

**New Features:**
- ✨ **Screenshot Capture** - Capture high-quality PNG/JPG screenshots with configurable resolution
- 🎞️ **GIF Export** - Export widgets as animated GIFs with quality presets (low/medium/high)
- 👆 **Touch Visualization** - Show touch indicators during recording with customizable appearance and ripple effects
- 📐 **Configurable Quality** - GIF quality presets with FPS and color control

**Improvements:**
- Enhanced API with new methods: `captureScreenshot()`, `exportAsGif()`, `startGifRecording()`, `stopGifRecording()`
- Added `TouchVisualizationConfig` for customizing touch indicators
- Added `ImageFormat` and `GifQuality` enums for better type safety
- Improved example app with dedicated demo page for new features

**Dependencies:**
- Added `image` package (^4.1.7) for GIF encoding

### Version 1.0.4

**Features:**
- MP4 video recording with H.264 codec
- Audio recording support (iOS & Android)
- Automatic permission handling
- Configurable FPS (15-60)
- High-quality video encoding
- Built-in error handling and callbacks

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
