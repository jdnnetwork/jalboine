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
  final String? guardianName;
  final String? guardianPhone;
  final DateTime? updatedAt;
  final bool unknownCallDetection;
  final bool locationTracking;
  final bool inactivityAlert;
  final bool batteryAlert;
  final bool emergencySound;

  const SeniorSettings({
    required this.userId,
    required this.enabledApps,
    required this.takesMedication,
    required this.emergencyContacts,
    this.guardianPinHash,
    this.soundMode = 'sound',
    this.batteryPct,
    this.online = true,
    this.guardianName,
    this.guardianPhone,
    this.updatedAt,
    this.unknownCallDetection = false,
    this.locationTracking = false,
    this.inactivityAlert = false,
    this.batteryAlert = false,
    this.emergencySound = false,
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
        guardianName: j['guardian_name'] as String?,
        guardianPhone: j['guardian_phone'] as String?,
        updatedAt: j['updated_at'] == null
            ? null
            : DateTime.parse(j['updated_at'] as String).toLocal(),
        unknownCallDetection:
            (j['unknown_call_detection'] as bool?) ?? false,
        locationTracking: (j['location_tracking'] as bool?) ?? false,
        inactivityAlert: (j['inactivity_alert'] as bool?) ?? false,
        batteryAlert: (j['battery_alert'] as bool?) ?? false,
        emergencySound: (j['emergency_sound'] as bool?) ?? false,
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
        'guardian_name': guardianName,
        'guardian_phone': guardianPhone,
        'unknown_call_detection': unknownCallDetection,
        'location_tracking': locationTracking,
        'inactivity_alert': inactivityAlert,
        'battery_alert': batteryAlert,
        'emergency_sound': emergencySound,
      };

  bool get hasGuardianContact =>
      (guardianName?.trim().isNotEmpty ?? false) &&
      (guardianPhone?.trim().isNotEmpty ?? false);

  SeniorSettings copyWith({
    List<String>? enabledApps,
    bool? takesMedication,
    List<EmergencyContact>? emergencyContacts,
    String? guardianPinHash,
    String? soundMode,
    int? batteryPct,
    bool? online,
    String? guardianName,
    String? guardianPhone,
    DateTime? updatedAt,
    bool? unknownCallDetection,
    bool? locationTracking,
    bool? inactivityAlert,
    bool? batteryAlert,
    bool? emergencySound,
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
        guardianName: guardianName ?? this.guardianName,
        guardianPhone: guardianPhone ?? this.guardianPhone,
        updatedAt: updatedAt ?? this.updatedAt,
        unknownCallDetection:
            unknownCallDetection ?? this.unknownCallDetection,
        locationTracking: locationTracking ?? this.locationTracking,
        inactivityAlert: inactivityAlert ?? this.inactivityAlert,
        batteryAlert: batteryAlert ?? this.batteryAlert,
        emergencySound: emergencySound ?? this.emergencySound,
      );

  static const empty = SeniorSettings(
    userId: '',
    enabledApps: [],
    takesMedication: false,
    emergencyContacts: [],
  );
}
