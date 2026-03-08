import 'package:flutter_test/flutter_test.dart';
import 'package:tafser/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TafserApp());

    // Basic check to see if the editor screen loads
    expect(find.byType(TafserApp), findsOneWidget);
  });
}
