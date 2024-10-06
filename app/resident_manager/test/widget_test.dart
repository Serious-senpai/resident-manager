import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart";
import "package:http/testing.dart";
import "package:resident_manager/main.dart";
import "package:resident_manager/src/state.dart";

final client = MockClient(
  (request) async {
    // print("Received request $request (path: ${request.url.path})");
    return Response("Not found", 404);
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel("plugins.flutter.io/path_provider"),
    (MethodCall methodCall) async {
      return "/tmp";
    },
  );

  testWidgets(
    "Drawer open",
    (tester) async {
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
      expect(find.image(const AssetImage("assets/flags/en.png")), findsOneWidget);
      expect(find.image(const AssetImage("assets/flags/vi.png")), findsOneWidget);
    },
  );
}
