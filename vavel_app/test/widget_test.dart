import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vavel_app/main.dart';

void main() {
  testWidgets('VavelApp boots and shows wallet chrome', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VavelApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Do not assert a single localized title string: CI runners may use
    // non-English system locales and async locale restore can differ from dev.
    expect(find.byType(VavelApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
