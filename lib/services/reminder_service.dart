import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

// ─────────────────────────────────────────────────────────────
//  ReminderService
//  Schedules a local notification for when the donor is next
//  eligible to donate (56 days after lastDonationDate).
//
//  Uses flutter_local_notifications (already in pubspec).
//  Timezone package is a transitive dependency — no pubspec change.
// ─────────────────────────────────────────────────────────────

class ReminderService {
  static final ReminderService _instance = ReminderService._();
  ReminderService._();
  factory ReminderService() => _instance;

  static const int _eligibilityNotifId = 1001;
  static const int _daysBeforeReminder  = 3; // remind 3 days before eligibility

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );
  }

  // ── Schedule eligibility reminder ───────────────────────────
  // Called whenever the user donates or the profile refreshes.
  // If lastDonationDate is null, any existing reminder is cancelled.
  Future<void> scheduleEligibilityReminder(DateTime? lastDonationDate) async {
    await init();
    // Cancel any previously scheduled reminder first
    await _plugin.cancel(_eligibilityNotifId);

    if (lastDonationDate == null) return;

    // Blood donation: 56-day (8-week) minimum gap
    final eligibleDate = lastDonationDate.add(const Duration(days: 56));
    final reminderDate =
        eligibleDate.subtract(Duration(days: _daysBeforeReminder));

    final now = DateTime.now();
    if (reminderDate.isBefore(now)) {
      // Already past the reminder window — no need to schedule
      return;
    }

    final scheduledTime = tz.TZDateTime.from(reminderDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'bloodconnect_reminders',
      'Donation Reminders',
      channelDescription: 'Reminders for when you can donate blood again',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
        android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      _eligibilityNotifId,
      'You can donate blood soon! 🩸',
      'You\'ll be eligible to donate again in $_daysBeforeReminder days. '
          'Check BloodConnect for active requests.',
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Cancel any pending reminder ──────────────────────────────
  Future<void> cancelEligibilityReminder() async {
    await init();
    await _plugin.cancel(_eligibilityNotifId);
  }

  // ── Eligibility helpers (pure logic, no async) ───────────────

  static const int donationGapDays = 56;

  /// Returns the date the donor is next eligible to donate.
  static DateTime? nextEligibleDate(DateTime? lastDonationDate) {
    if (lastDonationDate == null) return null;
    return lastDonationDate.add(const Duration(days: donationGapDays));
  }

  /// Returns true if the donor is currently eligible to donate.
  static bool isEligible(DateTime? lastDonationDate) {
    if (lastDonationDate == null) return true; // never donated = eligible
    final eligible = nextEligibleDate(lastDonationDate)!;
    return DateTime.now().isAfter(eligible);
  }

  /// Days remaining until eligible. Returns 0 if already eligible.
  static int daysUntilEligible(DateTime? lastDonationDate) {
    if (lastDonationDate == null) return 0;
    final eligible = nextEligibleDate(lastDonationDate)!;
    final diff = eligible.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inDays + 1;
  }

  /// Progress 0.0 → 1.0 through the 56-day cooldown period.
  static double eligibilityProgress(DateTime? lastDonationDate) {
    if (lastDonationDate == null) return 1.0;
    final now     = DateTime.now();
    final elapsed = now.difference(lastDonationDate).inDays;
    return (elapsed / donationGapDays).clamp(0.0, 1.0);
  }
}
