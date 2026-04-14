import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vavel_app/main.dart';

void main() {
  testWidgets('VavelApp builds without layout exceptions', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: VavelApp(),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(tester.takeException(), isNull);
    expect(find.byType(VavelApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
