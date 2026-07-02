import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_recorder_plus/widget_recorder_plus.dart';

void main() {
  group('WidgetRecorderController Tests', () {
    test('Controller initialization', () {
      final controller = WidgetRecorderController();
      expect(controller.isRecording, false);
      expect(controller.isRecordingGif, false);
      controller.dispose();
    });

    test('Controller with audio configuration', () {
      final controller = WidgetRecorderController(
        recordAudio: true,
      );
      expect(controller.recordAudio, true);
      controller.dispose();
    });

    test('Controller with touch visualization', () {
      final controller = WidgetRecorderController(
        showTouches: true,
        touchConfig: const TouchVisualizationConfig(
          color: Colors.red,
          size: 60,
        ),
      );
      expect(controller.showTouches, true);
      expect(controller.touchConfig.color, Colors.red);
      expect(controller.touchConfig.size, 60);
      controller.dispose();
    });

    test('FPS setter and getter', () {
      final controller = WidgetRecorderController();
      controller.fps = 30;
      // Note: fps is a setter, so we can't test the getter directly
      // This test verifies the setter doesn't throw
      controller.dispose();
    });
  });

  group('ImageFormat Enum', () {
    test('PNG format exists', () {
      expect(ImageFormat.png, isNotNull);
    });

    test('JPG format exists', () {
      expect(ImageFormat.jpg, isNotNull);
    });
  });

  group('GifQuality Enum', () {
    test('Low quality settings', () {
      expect(GifQuality.low.fps, 10);
      expect(GifQuality.low.colors, 64);
    });

    test('Medium quality settings', () {
      expect(GifQuality.medium.fps, 15);
      expect(GifQuality.medium.colors, 128);
    });

    test('High quality settings', () {
      expect(GifQuality.high.fps, 24);
      expect(GifQuality.high.colors, 256);
    });
  });

  group('TouchVisualizationConfig', () {
    test('Default configuration', () {
      const config = TouchVisualizationConfig();
      expect(config.color, Colors.blue);
      expect(config.size, 50.0);
      expect(config.opacity, 0.6);
      expect(config.showRipple, true);
      expect(config.rippleDuration, const Duration(milliseconds: 300));
    });

    test('Custom configuration', () {
      const config = TouchVisualizationConfig(
        color: Colors.red,
        size: 80.0,
        opacity: 0.8,
        showRipple: false,
        rippleDuration: Duration(milliseconds: 500),
      );
      expect(config.color, Colors.red);
      expect(config.size, 80.0);
      expect(config.opacity, 0.8);
      expect(config.showRipple, false);
      expect(config.rippleDuration, const Duration(milliseconds: 500));
    });
  });

  group('WidgetRecorder Widget Tests', () {
    testWidgets('WidgetRecorder renders child correctly', (WidgetTester tester) async {
      final controller = WidgetRecorderController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WidgetRecorder(
              controller: controller,
              child: const Text('Test Widget'),
            ),
          ),
        ),
      );

      expect(find.text('Test Widget'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('WidgetRecorder with touch visualization disabled', (WidgetTester tester) async {
      final controller = WidgetRecorderController(
        showTouches: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WidgetRecorder(
              controller: controller,
              child: Container(
                width: 200,
                height: 200,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
      controller.dispose();
    });

    testWidgets('WidgetRecorder with touch visualization enabled', (WidgetTester tester) async {
      final controller = WidgetRecorderController(
        showTouches: true,
        touchConfig: const TouchVisualizationConfig(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WidgetRecorder(
                controller: controller,
                child: Container(
                  width: 200,
                  height: 200,
                  color: Colors.blue,
                  child: const Text('Tap Me'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tap Me'), findsOneWidget);
      expect(find.byType(Listener), findsWidgets);
      
      controller.dispose();
    });

    testWidgets('Multiple controllers can be created', (WidgetTester tester) async {
      final controller1 = WidgetRecorderController();
      final controller2 = WidgetRecorderController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                WidgetRecorder(
                  controller: controller1,
                  child: const Text('Widget 1'),
                ),
                WidgetRecorder(
                  controller: controller2,
                  child: const Text('Widget 2'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Widget 1'), findsOneWidget);
      expect(find.text('Widget 2'), findsOneWidget);
      
      controller1.dispose();
      controller2.dispose();
    });
  });

  group('Integration Tests', () {
    testWidgets('Controller callbacks are set correctly', (WidgetTester tester) async {
      String? completedPath;
      String? errorMessage;

      final controller = WidgetRecorderController(
        onComplete: (path) => completedPath = path,
        onError: (error) => errorMessage = error,
      );

      expect(completedPath, isNull);
      expect(errorMessage, isNull);
      
      controller.dispose();
    });

    testWidgets('Widget renders with RepaintBoundary', (WidgetTester tester) async {
      final controller = WidgetRecorderController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WidgetRecorder(
              controller: controller,
              child: const Text('Boundary Test'),
            ),
          ),
        ),
      );

      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.text('Boundary Test'), findsOneWidget);
      
      controller.dispose();
    });
  });
}
