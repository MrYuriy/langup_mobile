import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/i18n.dart';
import 'core/providers.dart';
import 'core/router.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load the interface language before the first frame so t() is ready.
  final saved = await const FlutterSecureStorage().read(key: 'langup_ui_lang');
  await I18n.instance.load(I18n.resolveInitial(saved));
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
    final locale = ref.watch(localeProvider); // rebuild on a language change

    // Default the UI language to the account's native language on first sign-in
    // (only until the user picks one explicitly).
    ref.listen(authControllerProvider.select((s) => s.user?.nativeLanguage),
        (_, native) {
      if (native != null) {
        ref.read(localeProvider.notifier).syncToNative(native);
      }
    });

    return MaterialApp.router(
      title: 'LangUp',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: router,
      // go_router caches route pages, so a MaterialApp rebuild alone leaves most
      // screens on the old language. Keying the routed subtree by the current
      // language forces every visible screen to rebuild when it changes.
      builder: (context, child) => KeyedSubtree(
        key: ValueKey(locale),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
