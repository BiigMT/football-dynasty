import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/widgets/fd_ui_kit.dart';
import '../lib/theme/app_theme.dart';

void main() {
  testWidgets('rating badge displays the live player rating', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: const Scaffold(body: FdRatingBadge(84))));
    expect(find.text('84'), findsOneWidget);
  });

  testWidgets('form guide displays W D L markers', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: const Scaffold(
      body: FdFormGuide(results: [FdFormResult.win, FdFormResult.draw, FdFormResult.loss]),
    )));
    expect(find.text('W'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
    expect(find.text('L'), findsOneWidget);
  });

  testWidgets('stat tile fits a compact mobile layout', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: const Scaffold(
      body: Padding(padding: EdgeInsets.all(8), child: Row(children: [
        Expanded(child: FdStatTile(label: 'Budget', value: 'K12,500,000')),
        SizedBox(width: 8),
        Expanded(child: FdStatTile(label: 'Position', value: '1st')),
      ])),
    )));
    expect(tester.takeException(), isNull);
  });
}
