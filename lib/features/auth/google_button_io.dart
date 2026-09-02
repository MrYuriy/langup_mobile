import 'package:flutter/material.dart';

/// Android/iOS: an ordinary button. The app opens Google's account chooser
/// itself, so nothing platform-specific is needed beyond calling [onPressed].
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.onIdToken,
  });

  final String label;

  /// Runs the interactive sign-in. Null while another request is in flight.
  final VoidCallback? onPressed;

  /// Unused here; the web build delivers its token through this instead,
  /// because there the sign-in completes as an event rather than a return
  /// value.
  final ValueChanged<String>? onIdToken;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.g_mobiledata),
      label: Text(label),
    );
  }
}
