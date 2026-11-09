import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/i18n.dart';

/// A daily nudge at a time the learner picks.
///
/// Local, not push: there is nothing to send and nothing to host, it works with
/// the phone offline, and the thing being reminded about — a practice habit —
/// lives on the device anyway. The streak rule it protects forgives one missed
/// day, so this is a nudge, not an alarm.
///
/// Deliberately inexact (`inexactAllowWhileIdle`). Android 12 put exact alarms
/// behind a permission prompt, and a study reminder does not need to land on
/// the second — asking for that permission would cost more goodwill than the
/// precision is worth.
class ReminderService {
  ReminderService([FlutterSecureStorage? storage, FlutterLocalNotificationsPlugin? plugin])
      : _storage = storage ?? const FlutterSecureStorage(),
        _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterSecureStorage _storage;
  final FlutterLocalNotificationsPlugin _plugin;

  static const _kEnabled = 'langup_reminder_enabled';
  static const _kHour = 'langup_reminder_hour';
  static const _kMinute = 'langup_reminder_minute';

  /// One id, reused: there is only ever one reminder, and scheduling over it
  /// replaces the old one instead of stacking a second notification.
  static const _id = 1001;

  static const _channelId = 'study_reminder';

  bool _ready = false;

  /// Default when nothing has been chosen yet — evening, when someone is most
  /// likely to have a free ten minutes.
  static const defaultTime = TimeOfDay(hour: 20, minute: 0);

  Future<void> _init() async {
    if (_ready || kIsWeb) return;
    tzdata.initializeTimeZones();
    // The plugin schedules in a named zone, and only the device knows which;
    // without this every reminder would be scheduled in UTC.
    tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Asked for explicitly later, when the learner turns the reminder on
          // — a permission sheet on first launch, before they know what it is
          // for, is the one most likely to be refused.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// The stored setting: whether a reminder is on, and at what time.
  Future<({bool enabled, TimeOfDay at})> load() async {
    final enabled = await _storage.read(key: _kEnabled) == 'true';
    final hour = int.tryParse(await _storage.read(key: _kHour) ?? '');
    final minute = int.tryParse(await _storage.read(key: _kMinute) ?? '');
    final at = (hour == null || minute == null)
        ? defaultTime
        : TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
    return (enabled: enabled, at: at);
  }

  /// Turn the reminder on at [at]. False means the system refused permission.
  Future<bool> enable(TimeOfDay at) async {
    if (kIsWeb) return false;
    await _init();
    if (!await _askPermission()) return false;

    await _storage.write(key: _kEnabled, value: 'true');
    await _storage.write(key: _kHour, value: '${at.hour}');
    await _storage.write(key: _kMinute, value: '${at.minute}');
    await _schedule(at);
    return true;
  }

  Future<void> disable() async {
    await _storage.write(key: _kEnabled, value: 'false');
    if (kIsWeb) return;
    await _init();
    await _plugin.cancel(_id);
  }

  /// Re-schedule from storage on launch.
  ///
  /// Android reinstates scheduled notifications after a reboot through the
  /// plugin's own receiver, but a reminder is cheap to re-arm and this also
  /// picks up a changed interface language, since the text is baked in when the
  /// notification is scheduled rather than when it fires.
  Future<void> reapply() async {
    if (kIsWeb) return;
    final setting = await load();
    if (!setting.enabled) return;
    try {
      await _init();
      await _schedule(setting.at);
    } catch (e) {
      // A reminder is a nicety; never let it stop the app from starting.
      debugPrint('Could not re-arm the study reminder: $e');
    }
  }

  Future<bool> _askPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      // Android 13+ only; older versions answer null, which is not a refusal.
      return await android.requestNotificationsPermission() ?? true;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return true;
  }

  Future<void> _schedule(TimeOfDay at) async {
    await _plugin.zonedSchedule(
      _id,
      t('reminder.title'),
      t('reminder.body'),
      _nextOccurrence(at),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          t('reminder.channel'),
          channelDescription: t('reminder.channel_desc'),
          importance: Importance.defaultImportance,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // Repeats daily at the same clock time, following the device's zone
      // rather than a fixed offset — so it stays at 20:00 across a DST change.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextOccurrence(TimeOfDay at) {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, at.hour, at.minute);
    // Already past today, so the first one is tomorrow; otherwise a reminder
    // set for this morning would fire immediately.
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    return when;
  }
}
