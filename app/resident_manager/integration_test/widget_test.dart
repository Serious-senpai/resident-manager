import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:resident_manager/main.dart";
import "package:resident_manager/src/core/state.dart";
import "package:resident_manager/src/widgets/admin/reg_queue.dart";

const adminUsername = "admin";
const adminPassword = "NgaiLongGey";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    "Administrator login",
    (WidgetTester tester) async {
      final state = ApplicationState();
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
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.byWidgetPredicate((widget) => widget is RegisterQueuePage), findsOneWidget);
    },
  );
}
