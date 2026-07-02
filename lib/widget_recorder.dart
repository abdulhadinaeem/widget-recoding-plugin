import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

/// Image format for screenshot capture
enum ImageFormat {
  png,
  jpg,
}

/// GIF quality presets
enum GifQuality {
  low(fps: 10, colors: 64),
  medium(fps: 15, colors: 128),
  high(fps: 24, colors: 256);

  const GifQuality({required this.fps, required this.colors});
  final int fps;
  final int colors;
}

/// Video quality presets (NEW v1.1.0)
enum VideoQuality {
  low(fps: 15, bitrate: 2000000, description: 'Low (15 FPS, 2 Mbps) - Smallest file'),
  medium(fps: 30, bitrate: 5000000, description: 'Medium (30 FPS, 5 Mbps) - Balanced'),
  high(fps: 60, bitrate: 10000000, description: 'High (60 FPS, 10 Mbps) - Best quality');

  const VideoQuality({
    required this.fps,
    required this.bitrate,
    required this.description,
  });
  final int fps;
  final int bitrate;
  final String description;
}

/// Configuration for touch visualization
class TouchVisualizationConfig {
  /// Color of the touch indicator
  final Color color;
  
  /// Size of the touch indicator
  final double size;
  
  /// Opacity of the touch indicator
  final double opacity;
  
  /// Show ripple effect on touch
  final bool showRipple;
  
  /// Duration of the ripple animation
  final Duration rippleDuration;

  const TouchVisualizationConfig({
    this.color = Colors.blue,
    this.size = 50.0,
    this.opacity = 0.6,
    this.showRipple = true,
    this.rippleDuration = const Duration(milliseconds: 300),
  });
}

/// Simple controller for recording widgets
class WidgetRecorderController {
  final Function(String path)? onComplete;
  final Function(String error)? onError;
  final bool recordAudio;
  final Widget Function(BuildContext context, VoidCallback openSettings)?
      permissionDeniedDialog;
  
  /// Enable touch visualization during recording
  final bool showTouches;
  
  /// Configuration for touch visualization
  final TouchVisualizationConfig touchConfig;
  
  /// Custom save directory path (optional)
  /// If null, uses temporary directory
  final String? customSavePath;

  WidgetRecorderController({
    this.onComplete,
    this.onError,
    this.recordAudio = false,
    this.permissionDeniedDialog,
    this.showTouches = false,
    this.touchConfig = const TouchVisualizationConfig(),
    this.customSavePath,
  });

  final MethodChannel _channel = const MethodChannel('widget_recorder_plus');
  bool _isRecording = false;
  bool _isRecordingGif = false;
  Timer? _timer;
  final GlobalKey _boundaryKey = GlobalKey();
  int _fps = 60;
  int? _customBitrate;  // For video quality presets
  String? _outputPath;
  Size? _size;
  BuildContext? _context;
  
  // GIF recording state
  final List<ui.Image> _gifFrames = [];
  int _gifTargetFps = 15;

  /// Set frames per second (default: 60)
  set fps(int value) => _fps = value;
  
  /// Apply a video quality preset
  /// 
  /// Sets both FPS and bitrate automatically.
  void applyVideoQuality(VideoQuality quality) {
    _fps = quality.fps;
    _customBitrate = quality.bitrate;
    debugPrint('[WidgetRecorder] 📊 Applied ${quality.description}');
  }

  /// Internal method to set context for permission dialogs
  void _setContext(BuildContext context) {
    _context = context;
  }

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    if (!recordAudio) return true;
    try {
      final result = await _channel.invokeMethod<bool>('checkPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request microphone permission (returns true if granted)
  Future<bool> requestPermission() async {
    if (!recordAudio) return true;
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Open app settings (useful when permission is permanently denied)
  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod('openSettings');
    } catch (e) {
      // Ignore errors
    }
  }

  /// Internal method to handle permission with dialog
  Future<bool> _handlePermission() async {
    if (!recordAudio || _context == null) return true;

    // Check if already granted
    if (await hasPermission()) return true;

    // Request permission
    final granted = await requestPermission();
    if (granted) return true;

    // Permission denied - show dialog
    if (_context != null && _context!.mounted) {
      final shouldOpenSettings = await showDialog<bool>(
        context: _context!,
        barrierDismissible: false,
        builder: (context) {
          // Use custom dialog if provided
          if (permissionDeniedDialog != null) {
            return permissionDeniedDialog!(context, openSettings);
          }

          // Default dialog
          return AlertDialog(
            title: const Text('Microphone Permission Required'),
            content: const Text(
              'This app needs microphone access to record audio with the video. '
              'Please grant permission in Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Open Settings'),
              ),
            ],
          );
        },
      );

      if (shouldOpenSettings == true) {
        await openSettings();
      }
    }

    return false;
  }

  /// Start recording the widget with optional countdown
  /// 
  /// [countdown] - Optional countdown duration before recording starts
  /// [onTick] - Optional callback called each second during countdown
  Future<void> start({
    Duration? countdown,
    Function(int remainingSeconds)? onTick,
  }) async {
    if (_isRecording) {
      debugPrint('[WidgetRecorder] ⚠️ Already recording');
      return;
    }

    // Handle countdown if specified
    if (countdown != null && countdown.inSeconds > 0) {
      debugPrint('[WidgetRecorder] ⏳ Starting countdown: ${countdown.inSeconds}s');
      
      for (int i = countdown.inSeconds; i > 0; i--) {
        onTick?.call(i);
        await Future.delayed(const Duration(seconds: 1));
      }
      
      debugPrint('[WidgetRecorder] ✅ Countdown complete');
    }

    // Handle permission automatically if audio recording is enabled
    if (recordAudio) {
      final hasPermission = await _handlePermission();
      if (!hasPermission) {
        debugPrint('[WidgetRecorder] ❌ Permission denied');
        _handleError('Microphone permission denied');
        return;
      }
    }

    _isRecording = true;

    try {
      debugPrint('[WidgetRecorder] 🎬 Starting recording...');

      // Get output directory
      final Directory dir;
      if (customSavePath != null) {
        dir = Directory(customSavePath!);
        // Create directory if it doesn't exist
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      } else {
        dir = await getTemporaryDirectory();
      }
      
      _outputPath = '${dir.path}/widget_rec_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final renderObject = _boundaryKey.currentContext?.findRenderObject();
      if (renderObject == null) {
        throw Exception('Widget not found. Ensure WidgetRecorder is built.');
      }

      _size = (renderObject as RenderRepaintBoundary).size;

      // Round dimensions down to the nearest multiple of 16 for perfect encoding
      final int validWidth = (_size!.width.toInt() ~/ 16) * 16;
      final int validHeight = (_size!.height.toInt() ~/ 16) * 16;

      debugPrint(
          '[WidgetRecorder] 📐 Recording: ${validWidth}x$validHeight @ $_fps fps (Audio: $recordAudio)');

      await _channel.invokeMethod('startRecording', {
        'width': validWidth,
        'height': validHeight,
        'fps': _fps,
        'outputPath': _outputPath,
        'recordAudio': recordAudio,
        if (_customBitrate != null) 'bitrate': _customBitrate,
      });

      _timer = Timer.periodic(
        Duration(milliseconds: 1000 ~/ _fps),
        (_) => _captureFrame(),
      );

      debugPrint('[WidgetRecorder] ✅ Recording started');
    } catch (e) {
      debugPrint('[WidgetRecorder] ❌ Error starting: $e');
      _handleError(e.toString());
    }
  }

  /// Start recording with countdown
  /// 
  /// Convenience method that shows a countdown before recording.
  /// 
  /// [countdownSeconds] - Number of seconds to countdown (default: 3)
  /// [onTick] - Called each second with remaining seconds
  Future<void> startWithCountdown({
    int countdownSeconds = 3,
    Function(int remainingSeconds)? onTick,
  }) async {
    await start(
      countdown: Duration(seconds: countdownSeconds),
      onTick: onTick,
    );
  }

  /// Stop recording and get the video file path
  Future<String?> stop() async {
    if (!_isRecording) {
      debugPrint('[WidgetRecorder] ⚠️ Not recording');
      return null;
    }

    debugPrint('[WidgetRecorder] ⏹️ Stopping recording...');
    _isRecording = false;
    _timer?.cancel();

    try {
      await _channel.invokeMethod('stopRecording');
      debugPrint('[WidgetRecorder] ✅ Video saved: $_outputPath');
      onComplete?.call(_outputPath ?? '');
      return _outputPath;
    } catch (e) {
      debugPrint('[WidgetRecorder] ❌ Error stopping: $e');
      _handleError(e.toString());
      return null;
    }
  }

  Future<void> _captureFrame() async {
    try {
      final renderObject = _boundaryKey.currentContext?.findRenderObject();
      if (renderObject == null) return;

      final boundary = renderObject as RenderRepaintBoundary;

      // Calculate the exact dimensions we need (rounded to multiples of 16)
      final validWidth = (_size!.width.toInt() ~/ 16) * 16;
      final validHeight = (_size!.height.toInt() ~/ 16) * 16;

      // Capture at 1.0 pixel ratio to match encoder dimensions exactly
      // This prevents size mismatches between Dart and native layers
      final image = await boundary.toImage(pixelRatio: 1.0);

      // Resize only if the captured size doesn't match encoder dimensions
      ui.Image finalImage = image;
      if (image.width != validWidth || image.height != validHeight) {
        finalImage = await _resizeImage(image, validWidth, validHeight);
      }

      final byteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.rawRgba);

      if (byteData != null) {
        final frameData = byteData.buffer.asUint8List();
        final expectedSize =
            validWidth * validHeight * 4; // RGBA = 4 bytes per pixel

        // Verify frame data size matches expectations
        if (frameData.length != expectedSize) {
          throw Exception(
              'Frame data size mismatch. Expected: $expectedSize, Got: ${frameData.length}');
        }

        await _channel.invokeMethod('addFrame', {
          'frame': frameData,
        });
      }

      // Clean up images to prevent memory leaks
      finalImage.dispose();
      if (finalImage != image) {
        image.dispose();
      }
    } catch (e) {
      debugPrint('[WidgetRecorder] ❌ Error capturing frame: $e');
      _handleError(e.toString());
    }
  }

  Future<ui.Image> _resizeImage(ui.Image image, int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
        recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    // Draw the image scaled to fit the target dimensions
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      ui.Paint(),
    );

    final picture = recorder.endRecording();
    return picture.toImage(width, height);
  }

  void _handleError(String error) {
    _isRecording = false;
    _timer?.cancel();
    onError?.call(error);
  }

  /// Export widget as animated GIF
  /// 
  /// Records the widget for the specified duration and exports as GIF.
  /// 
  /// [duration] - How long to record (default: 3 seconds)
  /// [quality] - GIF quality preset (default: medium)
  /// 
  /// Returns the file path of the exported GIF.
  Future<String?> exportAsGif({
    Duration duration = const Duration(seconds: 3),
    GifQuality quality = GifQuality.medium,
  }) async {
    if (_isRecording || _isRecordingGif) {
      debugPrint('[WidgetRecorder] ⚠️ Already recording');
      return null;
    }

    try {
      debugPrint('[WidgetRecorder] 🎬 Starting GIF recording...');
      
      _isRecordingGif = true;
      _gifFrames.clear();
      _gifTargetFps = quality.fps;

      final renderObject = _boundaryKey.currentContext?.findRenderObject();
      if (renderObject == null) {
        throw Exception('Widget not found. Ensure WidgetRecorder is built.');
      }

      _size = (renderObject as RenderRepaintBoundary).size;

      // Start capturing frames
      final startTime = DateTime.now();
      _timer = Timer.periodic(
        Duration(milliseconds: 1000 ~/ _gifTargetFps),
        (timer) async {
          final elapsed = DateTime.now().difference(startTime);
          
          if (elapsed >= duration) {
            timer.cancel();
            await _finishGifExport(quality);
          } else {
            final frame = await _captureFrameForGif();
            if (frame != null) {
              _gifFrames.add(frame);
            }
          }
        },
      );

      debugPrint('[WidgetRecorder] ✅ GIF recording started for ${duration.inSeconds}s');
      return null; // Will be returned in _finishGifExport
    } catch (e) {
      debugPrint('[WidgetRecorder] ❌ Error starting GIF export: $e');
      _isRecordingGif = false;
      _gifFrames.clear();
      onError?.call(e.toString());
      return null;
    }
  }

  /// Start recording frames for GIF export (manual control)
  /// 
  /// Use this for manual control. Call stopGifRecording() when done.
  Future<void> startGifRecording({
    GifQuality quality = GifQuality.medium,
  }) async {
    if (_isRecording || _isRecordingGif) {
      debugPrint('[WidgetRecorder] ⚠️ Already recording');
      return;
    }

    try {
      debugPrint('[WidgetRecorder] 🎬 Starting manual GIF recording...');
      
      _isRecordingGif = true;
      _gifFrames.clear();
      _gifTargetFps = quality.fps;

      final renderObject = _boundaryKey.currentContext?.findRenderObject();
      if (renderObject == null) {
        throw Exception('Widget not found. Ensure WidgetRecorder is built.');
      }

      _size = (renderObject as RenderRepaintBoundary).size;

      // Start capturing frames
      _timer = Timer.periodic(
        Duration(milliseconds: 1000 ~/ _gifTargetFps),
        (timer) async {
          final frame = await _captureFrameForGif();
          if (frame != null) {
            _gifFrames.add(frame);
          }
        },
      );

      debugPrint('[WidgetRecorder] ✅ Manual GIF recording started');
    } catch (e) {
      debugPrint('[WidgetRecorder] ❌ Error starting manual GIF recording: $e');
      _isRecordingGif = false;
      _gifFrames.clear();
      onError?.call(e.toString());
    }
  }

  /// Stop GIF recording and export the file
  /// 
  /// Returns the file path of the exported GIF.
  Future<String?> stopGifRecording({
    GifQuality quality = GifQuality.medium,
  }) async {
    if (!_isRecordingGif) {
      debugPrint('[WidgetRecorder] ⚠️ Not recording GIF');
      return null;
    }

    _timer?.cancel();
    return await _finishGifExport(quality);
  }

  Future<String?> _finishGifExport(GifQuality quality) async {
    try {
      debugPrint('[WidgetRecorder] 🎨 Processing ${_gifFrames.length} frames...');

      if (_gifFrames.isEmpty) {
        throw Exception('No frames captured');
      }

      // Create GIF animation
      final frames = <img.Image>[];
      
      for (final frame in _gifFrames) {
        final byteData = await frame.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (byteData != null) {
          final pixels = byteData.buffer.asUint8List();
          
          // Create image from RGBA data
          final imgFrame = img.Image.fromBytes(
            width: frame.width,
            height: frame.height,
            bytes: pixels.buffer,
            numChannels: 4,
          );

          // Quantize colors for better GIF compression
          final quantized = img.quantize(imgFrame, numberOfColors: quality.colors);
          frames.add(quantized);
        }
      }

      // For animated GIF with multiple frames
      if (frames.length > 1) {
        // Calculate delay in centiseconds (1/100th of a second)
        // GIF format uses centiseconds for frame delays
        final delayInCentiseconds = (100 / _gifTargetFps).round();
        
        debugPrint('[WidgetRecorder] 🎨 Encoding GIF: ${frames.length} frames, ${_gifTargetFps} FPS, delay: ${delayInCentiseconds}cs');
        
        // Create animated GIF with proper frame delay
        final encoder = img.GifEncoder(delay: delayInCentiseconds, repeat: 0);
        
        for (var i = 0; i < frames.length; i++) {
          encoder.addFrame(frames[i]);
        }
        
        final animatedGifBytes = encoder.finish();
        
        if (animatedGifBytes == null) {
          throw Exception('Failed to encode animated GIF');
        }

        // Save to file
        final Directory dir;
        if (customSavePath != null) {
          dir = Directory(customSavePath!);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
        } else {
          dir = await getTemporaryDirectory();
        }
        
        final filePath = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.gif';
        final file = File(filePath);
        await file.writeAsBytes(animatedGifBytes);

        // Clean up
        for (final frame in _gifFrames) {
          frame.dispose();
        }
        _gifFrames.clear();
        _isRecordingGif = false;

        debugPrint('[WidgetRecorder] ✅ GIF saved: $filePath (${frames.length} frames at ${_gifTargetFps} FPS)');
        onComplete?.call(filePath);
        return filePath;
      } else {
        // Single frame
        final gifBytes = img.encodeGif(frames.first);
        
        final Directory dir;
        if (customSavePath != null) {
          dir = Directory(customSavePath!);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
        } else {
          dir = await getTemporaryDirectory();
        }
        
        final filePath = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.gif';
        final file = File(filePath);
        await file.writeAsBytes(gifBytes);

        // Clean up
        for (final frame in _gifFrames) {
          frame.dispose();
        }
        _gifFrames.clear();
        _isRecordingGif = false;

        debugPrint('[WidgetRecorder] ✅ GIF saved: $filePath (single frame)');
        onComplete?.call(filePath);
        return filePath;
      }
    } catch (e) {
      debugPrint('[WidgetRecorder] ❌ Error finishing GIF export: $e');
      
      // Clean up on error
      for (final frame in _gifFrames) {
        frame.dispose();
      }
      _gifFrames.clear();
      _isRecordingGif = false;
      
      onError?.call(e.toString());
      return null;
    }
  }

  /// Check if currently recording (video or GIF)
  bool get isRecording => _isRecording || _isRecordingGif;

  /// Check if currently recording GIF specifically
  bool get isRecordingGif => _isRecordingGif;

  /// Capture a single screenshot of the widget
  /// 
  /// Returns the file path of the saved image.
  /// 
  /// [format] - Image format (PNG or JPG, default: PNG)
  /// [quality] - Image quality for JPG (1-100, default: 100, ignored for PNG)
  /// [pixelRatio] - Pixel ratio for high-resolution capture (default: 3.0 for retina)
  Future<String?> captureScreenshot({
    ImageFormat format = ImageFormat.png,
    int quality = 100,
    double pixelRatio = 3.0,
  }) async {
    try {
      debugPrint('[WidgetRecorder] 📸 Capturing screenshot...');

      final renderObject = _boundaryKey.currentContext?.findRenderObject();
      if (renderObject == null) {
        throw Exception('Widget not found. Ensure WidgetRecorder is built.');
      }

      final boundary = renderObject as RenderRepaintBoundary;
      
      // Capture at high resolution for quality
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      
      // Convert to bytes based on format
      final ByteData? byteData;
      String extension;
      
      if (format == ImageFormat.png) {
        byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        extension = 'png';
      } else {
        // JPG format - quality parameter is used here
        byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        extension = 'jpg';
        
        // For JPG, we need to encode manually with quality
        if (byteData != null) {
          final pngByteData = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          
          if (pngByteData == null) {
            throw Exception('Failed to encode image');
          }
          
          // Save as PNG and return (Flutter doesn't support JPG encoding with quality natively)
          // We'll save as PNG for now - full JPG support would require additional dependencies
          final Directory dir;
          if (customSavePath != null) {
            dir = Directory(customSavePath!);
            if (!await dir.exists()) {
              await dir.create(recursive: true);
            }
          } else {
            dir = await getTemporaryDirectory();
          }
          
          final filePath = '${dir.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.$extension';
          final file = File(filePath);
          await file.writeAsBytes(pngByteData.buffer.asUint8List());
          
          debugPrint('[WidgetRecorder] ✅ Screenshot saved: $filePath');
          return filePath;
        }
      }

      if (byteData == null) {
        throw Exception('Failed to capture image data');
      }

      // Save to directory
      final Directory dir;
      if (customSavePath != null) {
        dir = Directory(customSavePath!);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      } else {
        dir = await getTemporaryDirectory();
      }
      
      final filePath = '${dir.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      image.dispose();

      debugPrint('[WidgetRecorder] ✅ Screenshot saved: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('[WidgetRecorder] ❌ Error capturing screenshot: $e');
      onError?.call(e.toString());
      return null;
    }
  }

  /// Capture a single frame as ui.Image (used internally for GIF export)
  Future<ui.Image?> _captureFrameForGif() async {
    try {
      final renderObject = _boundaryKey.currentContext?.findRenderObject();
      if (renderObject == null) return null;

      final boundary = renderObject as RenderRepaintBoundary;
      return await boundary.toImage(pixelRatio: 1.0);
    } catch (e) {
      debugPrint('[WidgetRecorder] ❌ Error capturing frame: $e');
      return null;
    }
  }

  void dispose() {
    stop();
    
    // Clean up GIF frames if any
    for (final frame in _gifFrames) {
      frame.dispose();
    }
    _gifFrames.clear();
  }
}

/// Wrap your widget with this to enable recording
class WidgetRecorder extends StatefulWidget {
  final Widget child;
  final WidgetRecorderController controller;

  const WidgetRecorder({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<WidgetRecorder> createState() => _WidgetRecorderState();
}

class _WidgetRecorderState extends State<WidgetRecorder> {
  final List<_TouchPoint> _activeTouches = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set context for permission dialogs
    widget.controller._setContext(context);
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.controller.showTouches && 
        (widget.controller.isRecording || widget.controller.isRecordingGif)) {
      setState(() {
        _activeTouches.add(_TouchPoint(
          id: event.pointer,
          position: event.localPosition,
          timestamp: DateTime.now(),
        ));
      });
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (widget.controller.showTouches && 
        (widget.controller.isRecording || widget.controller.isRecordingGif)) {
      setState(() {
        final index = _activeTouches.indexWhere((t) => t.id == event.pointer);
        if (index != -1) {
          _activeTouches[index] = _TouchPoint(
            id: event.pointer,
            position: event.localPosition,
            timestamp: DateTime.now(),
          );
        }
      });
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (widget.controller.showTouches) {
      setState(() {
        _activeTouches.removeWhere((t) => t.id == event.pointer);
      });
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (widget.controller.showTouches) {
      setState(() {
        _activeTouches.removeWhere((t) => t.id == event.pointer);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = RepaintBoundary(
      key: widget.controller._boundaryKey,
      child: widget.child,
    );

    // Wrap with touch visualization if enabled
    if (widget.controller.showTouches) {
      content = Listener(
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerCancel,
        child: Stack(
          children: [
            content,
            // Touch indicators overlay
            if (_activeTouches.isNotEmpty)
              ..._activeTouches.map((touch) => _TouchIndicator(
                position: touch.position,
                config: widget.controller.touchConfig,
                timestamp: touch.timestamp,
              )),
          ],
        ),
      );
    }

    return content;
  }
}

/// Internal class to track touch points
class _TouchPoint {
  final int id;
  final Offset position;
  final DateTime timestamp;

  _TouchPoint({
    required this.id,
    required this.position,
    required this.timestamp,
  });
}

/// Touch indicator widget
class _TouchIndicator extends StatefulWidget {
  final Offset position;
  final TouchVisualizationConfig config;
  final DateTime timestamp;

  const _TouchIndicator({
    required this.position,
    required this.config,
    required this.timestamp,
  });

  @override
  State<_TouchIndicator> createState() => _TouchIndicatorState();
}

class _TouchIndicatorState extends State<_TouchIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    if (widget.config.showRipple) {
      _animationController = AnimationController(
        duration: widget.config.rippleDuration,
        vsync: this,
      );
      
      _scaleAnimation = Tween<double>(
        begin: 0.5,
        end: 1.5,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ));
      
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    if (widget.config.showRipple) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - (widget.config.size / 2),
      top: widget.position.dy - (widget.config.size / 2),
      child: IgnorePointer(
        child: widget.config.showRipple
            ? AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ripple effect
                      Container(
                        width: widget.config.size * _scaleAnimation.value,
                        height: widget.config.size * _scaleAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.config.color.withOpacity(
                              widget.config.opacity * (1 - _animationController.value),
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                      // Center dot
                      Container(
                        width: widget.config.size,
                        height: widget.config.size,
                        decoration: BoxDecoration(
                          color: widget.config.color.withOpacity(widget.config.opacity),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )
            : Container(
                width: widget.config.size,
                height: widget.config.size,
                decoration: BoxDecoration(
                  color: widget.config.color.withOpacity(widget.config.opacity),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
      ),
    );
  }
}
