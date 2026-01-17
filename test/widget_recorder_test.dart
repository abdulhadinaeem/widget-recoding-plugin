import 'package:flutter_test/flutter_test.dart';
import 'package:widget_recorder/widget_recorder.dart';
import 'package:flutter/material.dart';

void main() {
  group('WidgetRecorderController', () {
    test('can be instantiated', () {
      final controller = WidgetRecorderController();
      expect(controller, isNotNull);
    });

    test('fps can be set', () {
      final controller = WidgetRecorderController();
      controller.fps = 24;
      // fps is a setter only, so we just verify no error occurs
      expect(controller, isNotNull);
    });

    test('callbacks can be set', () {
      String? completedPath;
      String? errorMessage;

      final controller = WidgetRecorderController(
        onComplete: (path) => completedPath = path,
        onError: (error) => errorMessage = error,
      );

      expect(controller, isNotNull);
      expect(completedPath, isNull);
      expect(errorMessage, isNull);
    });
  });

  group('WidgetRecorder', () {
    testWidgets('can be created with required parameters', (tester) async {
      final controller = WidgetRecorderController();

      await tester.pumpWidget(
        MaterialApp(
          home: WidgetRecorder(
            controller: controller,
            child: Container(),
          ),
        ),
      );

      expect(find.byType(WidgetRecorder), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('wraps child in RepaintBoundary', (tester) async {
      final controller = WidgetRecorderController();

      await tester.pumpWidget(
        MaterialApp(
          home: WidgetRecorder(
            controller: controller,
            child: Text('Test Widget'),
          ),
        ),
      );

      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.text('Test Widget'), findsOneWidget);
    });
  });
}
