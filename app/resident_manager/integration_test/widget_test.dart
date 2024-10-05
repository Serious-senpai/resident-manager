import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:resident_manager/main.dart";
import "package:resident_manager/src/config.dart";
import "package:resident_manager/src/state.dart";
import "package:resident_manager/src/widgets/home.dart";
import "package:resident_manager/src/widgets/register.dart";
import "package:resident_manager/src/widgets/admin/reg_queue.dart";

final rng = Random();
const WAIT_DURATION = Duration(seconds: 5);

String randomString(int length) {
  const chars = "abcdefghijklmnopqrstuvwxyz0123456789";
  return String.fromCharCodes(Iterable.generate(length, (_) => chars.codeUnitAt(rng.nextInt(chars.length))));
}

String randomDigits(int length) {
  const chars = "0123456789";
  return String.fromCharCodes(Iterable.generate(length, (_) => chars.codeUnitAt(rng.nextInt(chars.length))));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    "Administrator login",
    (tester) async {
      final state = ApplicationState();
      await state.prepare();

      await tester.pumpWidget(MainApplication(state: state));
      await tester.pumpAndSettle();

      // Authorization fields
      final fields = find.byWidgetPredicate((widget) => widget is TextField);
      expect(fields, findsExactly(2));

      await tester.enterText(fields.at(0), DEFAULT_ADMIN_USERNAME);
      await tester.enterText(fields.at(1), DEFAULT_ADMIN_PASSWORD);

      // Press the "Login as administrator" button
      await tester.tap(find.byIcon(Icons.admin_panel_settings_outlined));
      await tester.pumpAndSettle(WAIT_DURATION);

      expect(find.byWidgetPredicate((widget) => widget is RegisterQueuePage), findsOneWidget);
    },
  );

  testWidgets(
    "Resident registration",
    (tester) async {
      final state = ApplicationState();
      await state.prepare();

      await tester.pumpWidget(MainApplication(state: state));
      await tester.pumpAndSettle();

      // Press the "Register as resident" button
      await tester.tap(find.byIcon(Icons.how_to_reg_outlined));
      await tester.pumpAndSettle();

      expect(find.byWidgetPredicate((widget) => widget is RegisterPage), findsOneWidget);

      // Registration form fields
      final registrationFields = find.byWidgetPredicate((widget) => widget is TextFormField);

      expect(registrationFields, findsExactly(8));

      final fullname = randomString(20);
      final room = rng.nextInt(32767);
      final phone = randomDigits(10);
      final email = "$fullname@test.com";
      final username = randomString(12);
      final password = randomString(12);

      await tester.enterText(registrationFields.at(0), fullname);
      await tester.enterText(registrationFields.at(1), room.toString());
      // Skip birthday
      await tester.enterText(registrationFields.at(3), phone);
      await tester.enterText(registrationFields.at(4), email);
      await tester.enterText(registrationFields.at(5), username);
      await tester.enterText(registrationFields.at(6), password);
      await tester.enterText(registrationFields.at(7), password);

      // Tap the "Register" button
      await tester.tap(find.byIcon(Icons.how_to_reg_outlined));
      await tester.pumpAndSettle(WAIT_DURATION);

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu_outlined));
      await tester.pumpAndSettle();

      // Open login menu
      await tester.tap(find.byIcon(Icons.lock_outlined));
      await tester.pumpAndSettle();

      // Login as administrator
      final adminLoginFields = find.byWidgetPredicate((widget) => widget is TextField);
      expect(adminLoginFields, findsExactly(2));

      await tester.enterText(adminLoginFields.at(0), DEFAULT_ADMIN_USERNAME);
      await tester.enterText(adminLoginFields.at(1), DEFAULT_ADMIN_PASSWORD);

      // Press the "Login as administrator" button
      await tester.tap(find.byIcon(Icons.admin_panel_settings_outlined));
      await tester.pumpAndSettle(WAIT_DURATION);

      expect(find.byWidgetPredicate((widget) => widget is RegisterQueuePage), findsOneWidget);

      // Open search interface
      await tester.tap(find.byIcon(Icons.search_outlined));
      await tester.pumpAndSettle();

      final searchDialog = find.byWidgetPredicate((widget) => widget is SimpleDialog);
      expect(searchDialog, findsOneWidget);

      final searchFields = find.descendant(
        of: searchDialog,
        matching: find.byWidgetPredicate((widget) => widget is TextFormField),
      );
      expect(searchFields, findsExactly(3));

      await tester.enterText(registrationFields.at(0), fullname);
      await tester.enterText(registrationFields.at(1), room.toString());
      await tester.enterText(registrationFields.at(2), username);
      await tester.tap(find.descendant(of: searchDialog, matching: find.byIcon(Icons.done_outlined)));
      await tester.pumpAndSettle(WAIT_DURATION);

      // Exactly 2 checkboxes: 1 for "Select all", 1 for our search result
      final checkboxes = find.byWidgetPredicate((widget) => widget is Checkbox);
      expect(checkboxes, findsExactly(2));

      // Toggle 3 times
      await tester.tap(checkboxes.first);
      await tester.tap(checkboxes.last);
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      // Approve the registration request
      await tester.tap(find.byIcon(Icons.done_outlined));
      await tester.pumpAndSettle(WAIT_DURATION);

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu_outlined));
      await tester.pumpAndSettle();

      // Logout
      await tester.tap(find.byIcon(Icons.logout_outlined));
      await tester.pumpAndSettle();

      // Login as the newly created user
      final loginFields = find.byWidgetPredicate((widget) => widget is TextField);
      expect(loginFields, findsExactly(2));

      await tester.enterText(loginFields.at(0), username);
      await tester.enterText(loginFields.at(1), password);

      // Press the "Login as resident" button
      await tester.tap(find.byIcon(Icons.login_outlined));
      await tester.pumpAndSettle(WAIT_DURATION);

      // Reach the home page
      expect(find.byWidgetPredicate((widget) => widget is HomePage), findsOneWidget);
    },
  );
}
