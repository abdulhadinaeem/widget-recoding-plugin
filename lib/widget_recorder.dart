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

  WidgetRecorderController({
    this.onComplete,
    this.onError,
    this.recordAudio = false,
  });

  final MethodChannel _channel = const MethodChannel('widget_recorder_plus');
  bool _isRecording = false;
  Timer? _timer;
  final GlobalKey _boundaryKey = GlobalKey();
  int _fps = 60;
  String? _outputPath;
  Size? _size;

  /// Set frames per second (default: 60)
  set fps(int value) => _fps = value;

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

  /// Start recording the widget
  Future<void> start() async {
    if (_isRecording) return;
    _isRecording = true;

    try {
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

      // Calculate pixel ratio to maintain quality while matching target dimensions
      final double pixelRatioWidth = validWidth / _size!.width;
      final double pixelRatioHeight = validHeight / _size!.height;
      final double optimalPixelRatio = (pixelRatioWidth + pixelRatioHeight) / 2;

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
    } catch (e) {
      _handleError(e.toString());
    }
  }

  /// Stop recording and get the video file path
  Future<String?> stop() async {
    if (!_isRecording) return null;
    _isRecording = false;
    _timer?.cancel();

    try {
      await _channel.invokeMethod('stopRecording');
      onComplete?.call(_outputPath ?? '');
      return _outputPath;
    } catch (e) {
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
      
      // Calculate exact dimensions
      final validWidth = (_size!.width.toInt() ~/ 16) * 16;
      final validHeight = (_size!.height.toInt() ~/ 16) * 16;
      
      // Use pixel ratio that matches target dimensions exactly
      final pixelRatio = validWidth / _size!.width;
      
      // Capture at calculated pixel ratio for optimal quality
      final image = await boundary.toImage(pixelRatio: pixelRatio);

      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      if (byteData != null) {
        await _channel.invokeMethod('addFrame', {
          'frame': byteData.buffer.asUint8List(),
        });
      }
    } catch (e) {
      _handleError(e.toString());
    }
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
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: widget.controller._boundaryKey,
      child: widget.child,
    );
  }
}
