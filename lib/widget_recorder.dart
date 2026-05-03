import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Simple controller for recording widgets
class WidgetRecorderController {
  final Function(String path)? onComplete;
  final Function(String error)? onError;
  final bool recordAudio;
  final Widget Function(BuildContext context, VoidCallback openSettings)?
      permissionDeniedDialog;

  WidgetRecorderController({
    this.onComplete,
    this.onError,
    this.recordAudio = false,
    this.permissionDeniedDialog,
  });

  final MethodChannel _channel = const MethodChannel('widget_recorder_plus');
  bool _isRecording = false;
  Timer? _timer;
  final GlobalKey _boundaryKey = GlobalKey();
  int _fps = 60;
  String? _outputPath;
  Size? _size;
  BuildContext? _context;

  /// Set frames per second (default: 60)
  set fps(int value) => _fps = value;

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

  /// Start recording the widget
  Future<void> start() async {
    if (_isRecording) {
      debugPrint('[WidgetRecorder] ⚠️ Already recording');
      return;
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

      // Get temporary directory and create output path
      final dir = await getTemporaryDirectory();
      _outputPath =
          '${dir.path}/widget_rec_${DateTime.now().millisecondsSinceEpoch}.mp4';

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

  /// Check if currently recording
  bool get isRecording => _isRecording;

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

  void dispose() {
    stop();
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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set context for permission dialogs
    widget.controller._setContext(context);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: widget.controller._boundaryKey,
      child: widget.child,
    );
  }
}
