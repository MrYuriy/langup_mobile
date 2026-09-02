/// The "Continue with Google" control, which is a different thing on each
/// platform.
///
/// On Android and iOS the app opens the account chooser itself, so this is an
/// ordinary button. A browser will not allow that — the popup would be blocked
/// — so `google_sign_in_web` refuses `authenticate()` outright and Google's own
/// rendered button is the only supported entry point. The two implementations
/// therefore share nothing but this signature.
library;

export 'google_button_io.dart'
    if (dart.library.js_interop) 'google_button_web.dart';
