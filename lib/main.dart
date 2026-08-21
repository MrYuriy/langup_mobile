import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/router.dart';

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
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF3B5BDB));

    return MaterialApp.router(
      title: 'LangUp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: scheme, useMaterial3: true),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B5BDB),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
