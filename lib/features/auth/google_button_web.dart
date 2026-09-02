import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as gis;

import 'google_auth_service.dart';

/// Web: Google's own rendered button.
///
/// A browser will not open the account chooser from arbitrary code — the popup
/// is blocked — so `google_sign_in_web` refuses `authenticate()` and requires
/// this widget, which Google draws inside an iframe it controls.
///
/// The consequence is that sign-in arrives as an EVENT rather than as the
/// return value of a call. Nothing invokes `onPressed` here; the token comes
/// back through [onIdToken] instead, which is why the two platform buttons
/// share only their signature.
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.onIdToken,
  });

  final String label;

  /// Unused on web: the rendered button owns its own click.
  final VoidCallback? onPressed;

  /// Called with the id_token once Google has authenticated the user.
  final ValueChanged<String>? onIdToken;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _events;
  late final Future<void> _ready;

  @override
  void initState() {
    super.initState();
    // Subscribe BEFORE initializing: the plugin can replay a previous session
    // as soon as it starts, and a listener attached afterwards would miss it.
    _events = GoogleSignIn.instance.authenticationEvents.listen(_onEvent);
    _ready = GoogleAuthService().ensureInitialized();
  }

  void _onEvent(GoogleSignInAuthenticationEvent event) {
    if (event is! GoogleSignInAuthenticationEventSignIn) return;
    final token = event.user.authentication.idToken;
    if (token != null && token.isNotEmpty) widget.onIdToken?.call(token);
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Reserve the button's height so the form does not jump once Google's
          // iframe lands.
          return const SizedBox(height: 44);
        }
        if (snapshot.hasError) {
          return Text(
            widget.label,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          );
        }
        return SizedBox(
          height: 44,
          child: Center(child: gis.renderButton()),
        );
      },
    );
  }
}
