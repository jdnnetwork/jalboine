class EmergencyContact {
  final String name;
  final String phone;
  const EmergencyContact({required this.name, required this.phone});

  factory EmergencyContact.fromJson(Map<String, dynamic> j) =>
      EmergencyContact(
        name: j['name'] as String,
        phone: j['phone'] as String,
      );

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};
}

class SeniorSettings {
  final String userId;
  final List<String> enabledApps;
  final bool takesMedication;
  final List<EmergencyContact> emergencyContacts;
  final String? guardianPinHash;
  final String soundMode;
  final int? batteryPct;
  final bool online;

  const SeniorSettings({
    required this.userId,
    required this.enabledApps,
    required this.takesMedication,
    required this.emergencyContacts,
    this.guardianPinHash,
    this.soundMode = 'sound',
    this.batteryPct,
    this.online = true,
  });

  factory SeniorSettings.fromJson(Map<String, dynamic> j) => SeniorSettings(
        userId: j['user_id'] as String,
        enabledApps:
            List<String>.from((j['enabled_apps'] as List?) ?? const []),
        takesMedication: (j['takes_medication'] as bool?) ?? false,
        emergencyContacts: ((j['emergency_contacts'] as List?) ?? const [])
            .map((e) => EmergencyContact.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
        guardianPinHash: j['guardian_pin_hash'] as String?,
        soundMode: (j['sound_mode'] as String?) ?? 'sound',
        batteryPct: j['battery_pct'] as int?,
        online: (j['online'] as bool?) ?? true,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'enabled_apps': enabledApps,
        'takes_medication': takesMedication,
        'emergency_contacts':
            emergencyContacts.map((e) => e.toJson()).toList(),
        'guardian_pin_hash': guardianPinHash,
        'sound_mode': soundMode,
        'battery_pct': batteryPct,
        'online': online,
      };

  SeniorSettings copyWith({
    List<String>? enabledApps,
    bool? takesMedication,
    List<EmergencyContact>? emergencyContacts,
    String? guardianPinHash,
    String? soundMode,
    int? batteryPct,
    bool? online,
  }) =>
      SeniorSettings(
        userId: userId,
        enabledApps: enabledApps ?? this.enabledApps,
        takesMedication: takesMedication ?? this.takesMedication,
        emergencyContacts: emergencyContacts ?? this.emergencyContacts,
        guardianPinHash: guardianPinHash ?? this.guardianPinHash,
        soundMode: soundMode ?? this.soundMode,
        batteryPct: batteryPct ?? this.batteryPct,
        online: online ?? this.online,
      );

  static const empty = SeniorSettings(
    userId: '',
    enabledApps: [],
    takesMedication: false,
    emergencyContacts: [],
  );
}
