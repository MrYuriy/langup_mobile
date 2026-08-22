import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/router.dart';
import 'core/theme.dart';

void main() {
  runApp(const ProviderScope(child: LangUpApp()));
}

class LangUpApp extends ConsumerStatefulWidget {
  const LangUpApp({super.key});

  @override
  ConsumerState<LangUpApp> createState() => _LangUpAppState();
}

class _LangUpAppState extends ConsumerState<LangUpApp> {
  @override
  void initState() {
    super.initState();
    // Restore the session before the first frame's redirects settle.
    Future.microtask(
      () => ref.read(authControllerProvider.notifier).bootstrap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'LangUp',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
