/// The learner's practice run — matches `StreakOut`.
///
/// The rule behind it is "skip a day, but not two": practising at least every
/// other day keeps it alive. A streak that dies on one missed evening is a
/// reason to stop opening the app, not a reason to come back, so the forgiving
/// version is the deliberate one.
class Streak {
  const Streak({
    required this.current,
    required this.longest,
    required this.practisedToday,
    required this.daysLeft,
  });

  final int current;

  /// Already earned, and never taken away — which is why it is worth showing
  /// next to a run that has lapsed.
  final int longest;

  final bool practisedToday;

  /// Days, today included, on which practising still saves the run. 1 means
  /// today is the last chance.
  final int daysLeft;

  bool get atRisk => !practisedToday && daysLeft <= 1;

  factory Streak.fromJson(Map<String, dynamic> json) => Streak(
        current: json['current'] as int? ?? 0,
        longest: json['longest'] as int? ?? 0,
        practisedToday: json['practised_today'] as bool? ?? false,
        daysLeft: json['days_left'] as int? ?? 0,
      );
}
