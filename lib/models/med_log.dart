class MedLog {
  final String id;
  final String userId;
  final DateTime scheduledAt;
  final String status;
  final DateTime? takenAt;

  const MedLog({
    required this.id,
    required this.userId,
    required this.scheduledAt,
    required this.status,
    this.takenAt,
  });

  Map<String, dynamic> toInsert() => {
        'user_id': userId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'status': status,
        if (takenAt != null) 'taken_at': takenAt!.toIso8601String(),
      };
}
