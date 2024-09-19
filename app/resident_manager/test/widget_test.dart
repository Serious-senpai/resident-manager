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
      return ".";
    },
  );

  testWidgets(
    "Drawer test",
    (WidgetTester tester) async {
      final state = ApplicationState();
      await state.prepare();

      // Build our app and trigger a frame.
      await tester.pumpWidget(MainApplication(state: state));

      // Login page header
      expect(find.text("Login"), findsOneWidget);

      // Open drawer
      await tester.tap(find.byIcon(Icons.lock_outlined));
      await tester.pump();

      // Drawer header
      expect(find.text("Resident manager"), findsOneWidget);
    },
  );
}
