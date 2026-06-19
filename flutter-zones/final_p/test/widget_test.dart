import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:final_p/main.dart';
import 'package:final_p/providers/theme_provider.dart';

void main() {
  testWidgets('Zonez app starts', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const ZonezApp(),
      ),
    );
    expect(find.byType(ZonezApp), findsOneWidget);
  });
}
