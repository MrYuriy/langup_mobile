import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/i18n.dart';
import 'core/providers.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'features/playlists/playlists_controller.dart';
import 'features/practice/practice_controller.dart';
import 'features/vocabulary/vocabulary_controller.dart';

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

    // Drop cached, user-scoped data when a different account signs in — these
    // controllers aren't autoDispose, so without this the new user would see the
    // previous account's words/exercises until a manual refresh.
    ref.listen(authControllerProvider.select((s) => s.user?.id), (prev, next) {
      if (next != null && prev != next) {
        ref.invalidate(vocabularyControllerProvider);
        ref.invalidate(practiceControllerProvider);
        ref.invalidate(playlistsControllerProvider);
      }
    });

    return MaterialApp.router(
      title: 'LangUp',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        // Respect the reader's text size, but not without limit. A browser
        // carries its own text-scaling preference on top of the system one —
        // Chrome on Android has a slider of its own — so the same phone can
        // render the app noticeably larger in a tab than in the installed app,
        // which is what makes six navigation labels stop fitting.
        //
        // 1.3 keeps larger text genuinely usable while leaving the layout
        // standing; beyond that the labels wrap and the screen fights itself.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3),
          ),
          // go_router caches route pages, so a MaterialApp rebuild alone leaves
          // most screens on the old language. Keying the routed subtree by the
          // current language forces every visible screen to rebuild when it
          // changes.
          child: KeyedSubtree(
            key: ValueKey(locale),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
