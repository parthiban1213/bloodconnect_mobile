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
    await _rc.setConfigSettings(RemoteConfigSettings(
      // How long to wait for a network fetch before falling back to cache.
      fetchTimeout: const Duration(seconds: 10),
      // How often the config is re-fetched in production.
      // During development you can lower this to Duration.zero so every
      // launch fetches fresh values.
      minimumFetchInterval: const Duration(hours: 1),
    ));

    // Set safe defaults so the app works even if Remote Config has never
    // been configured yet — default values mean "no update needed".
    await _rc.setDefaults({
      'latest_version': '1.0.0',
      'force_update': false,
      'release_notes': '',
    });

    await _rc.fetchAndActivate();
  }

  /// Returns [UpdateInfo] describing whether (and how urgently) the user
  /// should update.  Always resolves — never throws.
  static Future<UpdateInfo> checkForUpdate() async {
    try {
      // Re-fetch so we always act on the freshest values.
      await _rc.fetchAndActivate();

      final latestVersion = _rc.getString('latest_version').trim();
      final isForced      = _rc.getBool('force_update');
      final releaseNotes  = _rc.getString('release_notes').trim();

      final info      = await PackageInfo.fromPlatform();
      final current   = info.version.trim();

      final hasUpdate = _isNewer(latestVersion, current);

      return UpdateInfo(
        hasUpdate: hasUpdate,
        isForced: isForced && hasUpdate,
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
