import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Holds the result of an update check.
class UpdateInfo {
  /// Whether any update is available at all.
  final bool hasUpdate;

  /// When true the user MUST update — no "later" option is offered.
  final bool isForced;

  /// The version string fetched from Remote Config (e.g. "1.2.0").
  final String latestVersion;

  /// Optional release notes shown in the "What's new" section.
  /// Newline-separated; each line becomes a bullet point.
  final String releaseNotes;

  const UpdateInfo({
    required this.hasUpdate,
    required this.isForced,
    required this.latestVersion,
    required this.releaseNotes,
  });

  /// Convenience — no update needed.
  const UpdateInfo.none()
      : hasUpdate = false,
        isForced = false,
        latestVersion = '',
        releaseNotes = '';
}

/// Checks Firebase Remote Config for a newer app version.
///
/// Remote Config keys expected:
///   latest_version  → String  e.g. "1.2.0"
///   force_update    → bool    true = mandatory update
///   release_notes   → String  newline-separated bullet text (optional)
///
/// To test without a live store:
///   1. Open Firebase console → Remote Config
///   2. Add / edit parameter  latest_version  and set it HIGHER than your
///      current pubspec version (e.g. "9.9.9" triggers the popup immediately)
///   3. Publish changes — the app picks it up on next launch / resume.
class AppUpdateService {
  AppUpdateService._();

  static final _rc = FirebaseRemoteConfig.instance;

  /// Call once at startup (after Firebase.initializeApp).
  static Future<void> initialize() async {
    try {
      await _rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        // 0 seconds during development so Firebase console changes are
        // picked up on every launch. Change to Duration(hours: 1) before
        // releasing to production.
        minimumFetchInterval: const Duration(seconds: 0),
      ));

      await _rc.setDefaults({
        'latest_version': '1.0.0',
        'force_update': false,
        'release_notes': '',
      });

      await _rc.fetchAndActivate();
    } catch (_) {
      // Silently ignore — the app will use cached/default values.
      // This prevents a Remote Config network error from crashing the app.
    }
  }

  /// Returns [UpdateInfo] describing whether (and how urgently) the user
  /// should update.  Always resolves — never throws.
  static Future<UpdateInfo> checkForUpdate() async {
    try {
      // Re-fetch for freshest values. If the fetch fails (e.g. no network),
      // we fall through and use whatever is cached from initialize().
      try { await _rc.fetchAndActivate(); } catch (_) {}

      final latestVersion = _rc.getString('latest_version').trim();
      // Read force_update safely — handles both Boolean and String type in
      // the Firebase console. If the value was accidentally saved as the
      // string "true" instead of a Boolean, getBool() returns false, so we
      // also check the raw string value as a fallback.
      final forceUpdate = _rc.getBool('force_update') ||
          _rc.getString('force_update').trim().toLowerCase() == 'true';
      final releaseNotes  = _rc.getString('release_notes').trim();

      final info      = await PackageInfo.fromPlatform();
      final current   = info.version.trim();

      final newerAvailable = _isNewer(latestVersion, current);

      // hasUpdate is true ONLY when a newer version actually exists.
      // force_update alone (with equal versions) should never trigger the popup.
      final hasUpdate = newerAvailable;

      // isForced is true when force_update flag is on AND a newer version exists.
      final isForced = forceUpdate && hasUpdate;

      return UpdateInfo(
        hasUpdate: hasUpdate,
        isForced: isForced,
        latestVersion: latestVersion,
        releaseNotes: releaseNotes,
      );
    } catch (_) {
      // Never crash the app because of an update check failure.
      return const UpdateInfo.none();
    }
  }

  /// Returns true when [remote] is strictly newer than [current].
  /// Both strings must follow semantic versioning (MAJOR.MINOR.PATCH).
  static bool _isNewer(String remote, String current) {
    try {
      final r = _parse(remote);
      final c = _parse(current);
      for (var i = 0; i < 3; i++) {
        if (r[i] > c[i]) return true;
        if (r[i] < c[i]) return false;
      }
      return false; // equal
    } catch (_) {
      return false;
    }
  }

  static List<int> _parse(String v) =>
      v.split('.').map((s) => int.tryParse(s) ?? 0).toList()
        ..addAll([0, 0, 0]) // pad in case fewer than 3 parts
        ..length = 3;
}
