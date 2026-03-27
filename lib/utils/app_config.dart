// ─────────────────────────────────────────────────────────────
//  AppConfig  —  single place to update all configurable
//               texts, labels, and asset references.
//  Change a value here; it propagates everywhere in the app.
// ─────────────────────────────────────────────────────────────

class AppConfig {
  // ── Support ─────────────────────────────────────────────────
  static const String supportUrl   = 'https://www.hsblood.in/support';
  static const String supportLabel = 'Get Support';

  // ── Branding ────────────────────────────────────────────────
  static const String appName          = 'BloodConnect';
  static const String orgName          = 'HSBlood';
  static const String appVersion       = '1.0';
  static const String footerText       = '$appName · $orgName v$appVersion';

  // ── Splash ──────────────────────────────────────────────────
  static const String splashBrandBold  = 'HS';
  static const String splashBrandLight = 'Blood';
  static const String splashTagline    = 'Every drop counts.';

  // ── Login — OTP screen ──────────────────────────────────────
  static const String otpEyebrow       = 'Blood Donor Registry';
  static const String otpHeading       = 'Welcome\nback';
  static const String otpSubtext       = 'Sign in with your registered mobile\nnumber to see blood requests near you.';
  static const String otpContinueBtn   = 'Continue with OTP →';
  static const String otpSwitchBtn     = 'Sign in with Username & Password';
  static const String otpHintTitle     = 'New here?';
  static const String otpHintBody      = 'Contact your $orgName administrator to register as a donor. All accounts are managed centrally.';
  static const String otpCountryFlag   = '🇮🇳';
  static const String otpCountryCode   = '+91';
  static const String otpPlaceholder   = '98765 43210';
  static const int    otpTimerSeconds  = 60;

  // ── Login — Password screen ──────────────────────────────────
  static const String pwdHeading       = 'Welcome\nback';
  static const String pwdSubtext       = 'Sign in to see blood requests\nnear you and save lives.';
  static const String pwdSignInBtn     = 'Sign in →';
  static const String pwdSwitchBtn     = 'Sign in with OTP instead';
  static const String pwdHintTitle     = 'Need access?';
  static const String pwdHintBody      = 'Contact your administrator for login credentials. All accounts are managed by $orgName admin.';

  // ── Login — Forgot Password screen ──────────────────────────
  static const String fpResetBtn       = 'Reset Password →';
  static const String fpHintTitle      = 'Need help?';
  static const String fpHintBody       = 'Make sure the email matches the one registered with your $orgName account. Contact your administrator if you have forgotten your username.';
  static const String fpSuccessMsg     = 'Password reset successful! You can now sign in with your new password.';

  // ── Feed screen ──────────────────────────────────────────────
  static const String feedSearchHint   = 'Search hospital or blood type…';

  // Feed filter chips
  // key = value the RequirementsViewModel.setFilter() expects
  // label = display text in the horizontal scroll bar
  // From HSBlood admin panel: urgency = Critical/High/Medium/Low,
  // status = Open/Fulfilled/Cancelled
  static const List<Map<String, String>> feedFilters = [
    {'label': 'All',        'key': 'All'},
    {'label': 'Critical',   'key': 'Critical'},
    {'label': 'High',       'key': 'High'},
    {'label': 'Medium',     'key': 'Medium'},
    {'label': 'Low',        'key': 'Low'},
    {'label': 'Open',       'key': 'Open'},
    {'label': 'Fulfilled',  'key': 'Fulfilled'},
    {'label': 'Cancelled',  'key': 'Cancelled'},
  ];

  // ── Profile screen ───────────────────────────────────────────
  static const String profileDonationLabel = 'Units\nDonated';
}
