// A confirm dialog has to be dismissed with ITS OWN context.
//
// Every screen in this app sits inside StatefulShellRoute.indexedStack, which
// gives each branch its own Navigator. showDialog defaults to the ROOT
// navigator, so popping with the screen's context aims at the wrong one: the
// dialog's future never completes, and the code waiting on `await showDialog`
// simply never runs. That is how the delete button came to do nothing at all —
// no request was ever sent.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A screen inside a nested navigator, like every screen behind the shell.
class _Screen extends StatefulWidget {
  const _Screen({required this.popWithDialogContext});

  /// true  — the fix: pop the dialog with the context showDialog handed us.
  /// false — the bug: pop with the screen's context.
  final bool popWithDialogContext;

  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> {
  bool? answer;
  bool returned = false;

  Future<void> _confirm() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(
              widget.popWithDialogContext ? dialogContext : context,
              true,
            ),
            child: const Text('confirm'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() {
      returned = true;
      answer = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(returned ? 'answer=$answer' : 'still waiting'),
          TextButton(onPressed: _confirm, child: const Text('open')),
        ],
      ),
    );
  }
}

/// MaterialApp's own Navigator plus one nested inside it — the same two levels
/// the shell produces.
Widget _appWithNestedNavigator({required bool popWithDialogContext}) {
  return MaterialApp(
    home: Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => _Screen(popWithDialogContext: popWithDialogContext),
      ),
    ),
  );
}

Future<void> _openAndConfirm(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(find.text('confirm'), findsOneWidget, reason: 'the dialog should be up');
  await tester.tap(find.text('confirm'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('confirming returns true when popped with the dialog context', (tester) async {
    await tester.pumpWidget(_appWithNestedNavigator(popWithDialogContext: true));
    await _openAndConfirm(tester);

    expect(find.text('answer=true'), findsOneWidget);
  });

  testWidgets('popping with the screen context takes the screen, not the dialog', (tester) async {
    // The bug, pinned. The dialog goes on the root navigator; the screen's
    // context reaches the branch one, whose top route is the screen itself. So
    // the confirm button dismisses the SCREEN, the dialog stays up, and
    // `await showDialog` never returns — which makes everything after it,
    // including the delete request, unreachable. That is why the server saw no
    // DELETE at all while the button appeared to do nothing.
    await tester.pumpWidget(_appWithNestedNavigator(popWithDialogContext: false));
    await _openAndConfirm(tester);

    expect(find.text('confirm'), findsOneWidget, reason: 'the dialog is still up');
    expect(find.text('open'), findsNothing, reason: 'the screen underneath was popped');
    expect(find.textContaining('answer='), findsNothing, reason: 'the caller was never answered');
  });
}
