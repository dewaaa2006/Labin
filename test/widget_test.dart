import 'package:flutter_test/flutter_test.dart';
import 'package:labin/main.dart';

void main() {
  testWidgets('Labin app renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const LabinApp());

    expect(find.text('Labin'), findsOneWidget);
    expect(find.text('Lab Smarter, Not Harder'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();

    expect(find.text('Satu App, Semua Kebutuhan Lab'), findsOneWidget);
  });
}
