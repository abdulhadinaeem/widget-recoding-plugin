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

  WidgetRecorderController({this.onComplete, this.onError});

  final MethodChannel _channel = const MethodChannel('widget_recorder');
  bool _isRecording = false;
  Timer? _timer;
  final GlobalKey _boundaryKey = GlobalKey();
  int _fps = 60;
  String? _outputPath;
  Size? _size;

  /// Set frames per second (default: 30)
  set fps(int value) => _fps = value;

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

      await _channel.invokeMethod('startRecording', {
        'width': validWidth,
        'height': validHeight,
        'fps': _fps,
        'outputPath': _outputPath,
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
      // Capture at 2x pixel ratio for better quality
      final image = await boundary.toImage(pixelRatio: 2.0);

      // Resize image to match encoded dimensions if needed
      final validWidth = (_size!.width.toInt() ~/ 16) * 16;
      final validHeight = (_size!.height.toInt() ~/ 16) * 16;

      ui.Image resizedImage = image;
      if (image.width != validWidth || image.height != validHeight) {
        resizedImage = await _resizeImage(image, validWidth, validHeight);
      }

      final byteData =
          await resizedImage.toByteData(format: ui.ImageByteFormat.rawRgba);

      if (byteData != null) {
        await _channel.invokeMethod('addFrame', {
          'frame': byteData.buffer.asUint8List(),
        });
      }
    } catch (e) {
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
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: widget.controller._boundaryKey,
      child: widget.child,
    );
  }
}
