class PairLink {
  final String id;
  final String? seniorUserId;
  final String? guardianUserId;
  final String status;
  final String? inviteCode;

  const PairLink({
    required this.id,
    this.seniorUserId,
    this.guardianUserId,
    required this.status,
    this.inviteCode,
  });

  factory PairLink.fromJson(Map<String, dynamic> j) => PairLink(
        id: j['id'] as String,
        seniorUserId: j['senior_user_id'] as String?,
        guardianUserId: j['guardian_user_id'] as String?,
        status: j['status'] as String,
        inviteCode: j['invite_code'] as String?,
      );
}
