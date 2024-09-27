import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart";
import "package:http/testing.dart";
import "package:resident_manager/main.dart";
import "package:resident_manager/src/core/state.dart";
import "package:resident_manager/src/widgets/admin/reg_queue.dart";

final client = MockClient(
  (request) async {
    // print("Received request $request (path: ${request.url.path})");
    if (request.method == "POST") {
      if (request.url.path == "/api/v1/admin/login") {
        return Response("", 204);
      }
    }

    return Response("Not found", 404);
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel("plugins.flutter.io/path_provider"),
    (MethodCall methodCall) async {
      return ".test";
    },
  );

  testWidgets(
    "Drawer open",
    (WidgetTester tester) async {
      final state = ApplicationState(client: client);
      await state.prepare();

      await tester.pumpWidget(MainApplication(state: state));
      await tester.pump();

      // Do not match drawer images
      expect(find.image(const AssetImage("assets/apartment.png")), findsNothing);
      expect(find.image(const AssetImage("assets/github/github-mark.png")), findsNothing);
      expect(find.image(const AssetImage("assets/flags/en.png")), findsNothing);
      expect(find.image(const AssetImage("assets/flags/vi.png")), findsNothing);

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu_outlined));
      await tester.pumpAndSettle();

      // Match drawer images
      // expect(find.image(const AssetImage("assets/apartment.png")), findsOneWidget);
      expect(find.image(const AssetImage("assets/github/github-mark.png")), findsOneWidget);
      expect(find.image(const AssetImage("assets/flags/en.png")), findsOneWidget);
      expect(find.image(const AssetImage("assets/flags/vi.png")), findsOneWidget);
    },
  );

  testWidgets(
    "Administrator login",
    (WidgetTester tester) async {
      final state = ApplicationState(client: client);
      await state.prepare();

      await tester.pumpWidget(MainApplication(state: state));
      await tester.pumpAndSettle();

      // Authorization fields
      // No need to enter correct credentials since HTTP requests are mocked anyway.
      final fields = find.byWidgetPredicate((widget) => widget is TextField);
      expect(fields, findsExactly(2));

      // Press the "Login as admin" button
      await tester.tap(find.byIcon(Icons.admin_panel_settings_outlined));
      await tester.pumpAndSettle();

      expect(find.byWidgetPredicate((widget) => widget is RegisterQueuePage), findsOneWidget);
    },
  );
}
