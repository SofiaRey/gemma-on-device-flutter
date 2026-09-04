import 'package:fcl_2026_demo/app/app.dart';
import 'package:fcl_2026_demo/chat/chat.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App', () {
    testWidgets('renders ChatPage', (tester) async {
      await tester.pumpWidget(const App());
      await tester.pump();
      expect(find.byType(ChatPage), findsOneWidget);
    });
  });
}
