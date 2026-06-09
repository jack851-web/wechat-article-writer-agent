import 'package:flutter_test/flutter_test.dart';
import 'package:writeragent_frontend/main.dart';

void main() {
  testWidgets('WriterAgent app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const WriterAgentApp());
    expect(find.text('WriterAgent'), findsOneWidget);
  });
}
