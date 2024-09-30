import "dart:convert";
import "dart:io";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart";
import "package:http/testing.dart";
import "package:pinenacl/x25519.dart";
import "package:resident_manager/main.dart";
import "package:resident_manager/src/core/state.dart";
import "package:resident_manager/src/widgets/admin/reg_queue.dart";

final serverKey = PrivateKey.fromSeed(base64.decode(Platform.environment["PRIVATE_KEY_SEED"]!));
const adminUsername = "admin";
const adminPassword = "password";

final client = MockClient(
  (request) async {
    // print("Received request $request (path: ${request.url.path})");
    if (request.method == "POST") {
      if (request.url.path == "/api/v1/admin/login") {
        final username = request.headers["username"];
        final encrypted = request.headers["encrypted"];
        final pkey = request.headers["pkey"];

        if (username == null || encrypted == null || pkey == null) {
          return Response("", 422);
        }

        if (username != adminUsername) {
          return Response("", 403);
        }

        // https://github.com/ilap/pinenacl-dart/blob/master/example/box.dart
        final box = Box(myPrivateKey: serverKey, theirPublicKey: PublicKey(base64.decode(pkey)));
        final password = utf8.decode(box.decrypt(EncryptedMessage.fromList(base64.decode(encrypted))));

        if (password != adminPassword) {
          return Response("", 403);
        }

        return Response("", 204);
      }
    } else if (request.method == "GET") {}

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
      final fields = find.byWidgetPredicate((widget) => widget is TextField);
      expect(fields, findsExactly(2));

      await tester.enterText(fields.at(0), adminUsername);
      await tester.enterText(fields.at(1), adminPassword);

      // Press the "Login as admin" button
      await tester.tap(find.byIcon(Icons.admin_panel_settings_outlined));
      await tester.pumpAndSettle();

      expect(find.byWidgetPredicate((widget) => widget is RegisterQueuePage), findsOneWidget);
    },
  );
}
