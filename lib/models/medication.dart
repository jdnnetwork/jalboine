class Medication {
  final String id;
  final String userId;
  final List<String> times;
  final int timesPerDay;

  const Medication({
    required this.id,
    required this.userId,
    required this.times,
    required this.timesPerDay,
  });

  factory Medication.fromJson(Map<String, dynamic> j) => Medication(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        times: List<String>.from((j['times'] as List?) ?? const []),
        timesPerDay: (j['times_per_day'] as int?) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'times': times,
        'times_per_day': timesPerDay,
      };
}
