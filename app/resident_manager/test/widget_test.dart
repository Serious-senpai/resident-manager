import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:resident_manager/main.dart";
import "package:resident_manager/src/core/state.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel("plugins.flutter.io/path_provider"),
    (MethodCall methodCall) async {
      return ".test";
    },
  );

  testWidgets(
    "Drawer test",
    (WidgetTester tester) async {
      final state = ApplicationState();
      await state.prepare();

      await tester.pumpWidget(MainApplication(state: state));
      await tester.pump();

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu_outlined));
      await tester.pump();

      // Match drawer images
      expect(find.widgetWithImage(IconButton, const AssetImage("assets/github/github-mark.png")), findsOneWidget);
      expect(find.widgetWithImage(IconButton, const AssetImage("assets/flags/en.png")), findsOneWidget);
      expect(find.widgetWithImage(IconButton, const AssetImage("assets/flags/vi.png")), findsOneWidget);
    },
  );
}
