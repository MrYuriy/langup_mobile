import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:langup_mobile/main.dart';

void main() {
  testWidgets('App boots to the splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LangUpApp()));
    // Before the session is restored the router shows a loading splash.
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
