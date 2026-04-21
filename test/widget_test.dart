import 'package:flutter_test/flutter_test.dart';
import 'package:desfire_nfc_android/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const DesFireApp());
    expect(find.text("DESFire EV1 Generator"), findsOneWidget);
  });
}