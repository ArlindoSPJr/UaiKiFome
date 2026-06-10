import 'package:flutter_test/flutter_test.dart';
import 'package:uaikifome/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const UaiKiFomeApp());
    expect(find.text('UaiKiFome — carregando...'), findsOneWidget);
  });
}
