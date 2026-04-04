import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around FlutterSecureStorage for simple boolean / string flags.
/// Uses the same storage backend as ApiClient so no extra dependency is needed.
class PrefsService {
  static const _storage = FlutterSecureStorage();

  // ── Key ──────────────────────────────────────────────────────────────────
  /// Set to "1" right after a successful registration.
  /// Cleared as soon as the user either taps "Update Password" or "Skip".
  static const _kShowPasswordPrompt = 'show_password_prompt';

  // ── Registration prompt ──────────────────────────────────────────────────

  /// Call this immediately after successful registration.
  static Future<void> setShowPasswordPrompt() async {
    await _storage.write(key: _kShowPasswordPrompt, value: '1');
  }

  /// Returns true the first time (prompt should be shown), false afterwards.
  static Future<bool> shouldShowPasswordPrompt() async {
    final val = await _storage.read(key: _kShowPasswordPrompt);
    return val == '1';
  }

  /// Call this when the user acts on the prompt (navigate or skip).
  static Future<void> clearPasswordPrompt() async {
    await _storage.delete(key: _kShowPasswordPrompt);
  }
}
