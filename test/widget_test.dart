import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jalboine/core/theme.dart';

void main() {
  testWidgets('Theme has senior palette', (tester) async {
    final theme = JTheme.light();
    expect(theme.scaffoldBackgroundColor, JTheme.seniorBg);
    expect(theme.colorScheme.error, JTheme.sos);
  });

  testWidgets('App boots with theme', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: JTheme.light(),
      home: const Scaffold(body: Text('잘보이네')),
    ));
    expect(find.text('잘보이네'), findsOneWidget);
  });
}
