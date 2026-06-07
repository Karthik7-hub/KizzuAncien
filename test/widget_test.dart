import 'package:flutter_test/flutter_test.dart';
import 'package:kizzu_ancien/main.dart';

void main() {
  testWidgets('App load test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We don't have a counter anymore, so just check if it builds.
    await tester.pumpWidget(const KizzuAncienApp());
  });
}
