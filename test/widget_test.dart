import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vavel_wallet/main.dart';

void main() {
  testWidgets('VavelApp boots and shows wallet chrome', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VavelApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('VAVEL WALLET'), findsOneWidget);
  });
}
