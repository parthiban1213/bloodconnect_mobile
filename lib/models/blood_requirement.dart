class BloodRequirement {
  final String id;
  final String patientName;
  final String hospital;
  final String location;
  final String contactPerson;
  final String contactPhone;
  final String bloodType;
  final int unitsRequired;
  // Backend stores progress as remainingUnits + donations array
  final int remainingUnits;
  final int donationsCount;
  final String urgency;
  final DateTime? requiredBy;
  final String notes;
  final String status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  /// Usernames of every donor who has pledged to this requirement.
  /// Populated from the `donations[].donorUsername` array returned by the server.
  /// Used to show "Already Donated" without any client-side storage.
  final List<String> donorUsernames;

  BloodRequirement({
    required this.id,
    required this.patientName,
    required this.hospital,
    this.location = '',
    required this.contactPerson,
    required this.contactPhone,
    required this.bloodType,
    required this.unitsRequired,
    int? remainingUnits,
    this.donationsCount = 0,
    this.urgency = 'Medium',
    this.requiredBy,
    this.notes = '',
    this.status = 'Open',
    this.createdBy = '',
    required this.createdAt,
    required this.updatedAt,
    this.donorUsernames = const [],
  }) : remainingUnits = remainingUnits ?? unitsRequired;

  factory BloodRequirement.fromJson(Map<String, dynamic> json) {
    final unitsRequired = (json['unitsRequired'] as num?)?.toInt() ?? 1;

    // Backend field is 'remainingUnits', not 'unitsFulfilled'
    final remainingUnits = json['remainingUnits'] != null
        ? (json['remainingUnits'] as num).toInt()
        : unitsRequired;

    // donationsCount comes from enriched /my-requirements response
    final donationsCount = (json['donationsCount'] as num?)?.toInt() ??
        (json['donations'] is List
            ? (json['donations'] as List).length
            : 0);

    // Parse donor usernames from the donations array so the app can
    // determine server-side whether the current user already donated.
    final donorUsernames = <String>[];
    if (json['donations'] is List) {
      for (final d in (json['donations'] as List)) {
        if (d is Map<String, dynamic>) {
          final uname = d['donorUsername']?.toString();
          if (uname != null && uname.isNotEmpty) {
            donorUsernames.add(uname);
          }
        }
      }
    }

    return BloodRequirement(
      id:             json['_id']?.toString() ?? '',
      patientName:    json['patientName'] ?? '',
      hospital:       json['hospital'] ?? '',
      location:       json['location'] ?? '',
      contactPerson:  json['contactPerson'] ?? '',
      contactPhone:   json['contactPhone'] ?? '',
      bloodType:      json['bloodType'] ?? '',
      unitsRequired:  unitsRequired,
      remainingUnits: remainingUnits,
      donationsCount: donationsCount,
      urgency:        json['urgency'] ?? 'Medium',
      requiredBy: json['requiredBy'] != null
          ? DateTime.tryParse(json['requiredBy'].toString())
          : null,
      notes:          json['notes'] ?? '',
      status:         json['status'] ?? 'Open',
      createdBy:      json['createdBy']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      donorUsernames: donorUsernames,
    );
  }

  Map<String, dynamic> toJson() => {
        'patientName':   patientName,
        'hospital':      hospital,
        'location':      location,
        'contactPerson': contactPerson,
        'contactPhone':  contactPhone,
        'bloodType':     bloodType,
        'unitsRequired': unitsRequired,
        'urgency':       urgency,
        'requiredBy':    requiredBy?.toIso8601String(),
        'notes':         notes,
        'status':        status,
      };

  BloodRequirement copyWith({
    String? id, String? patientName, String? hospital, String? location,
    String? contactPerson, String? contactPhone, String? bloodType,
    int? unitsRequired, int? remainingUnits, int? donationsCount,
    String? urgency, DateTime? requiredBy, String? notes, String? status,
    String? createdBy, DateTime? createdAt, DateTime? updatedAt,
    List<String>? donorUsernames,
  }) {
    return BloodRequirement(
      id:             id ?? this.id,
      patientName:    patientName ?? this.patientName,
      hospital:       hospital ?? this.hospital,
      location:       location ?? this.location,
      contactPerson:  contactPerson ?? this.contactPerson,
      contactPhone:   contactPhone ?? this.contactPhone,
      bloodType:      bloodType ?? this.bloodType,
      unitsRequired:  unitsRequired ?? this.unitsRequired,
      remainingUnits: remainingUnits ?? this.remainingUnits,
      donationsCount: donationsCount ?? this.donationsCount,
      urgency:        urgency ?? this.urgency,
      requiredBy:     requiredBy ?? this.requiredBy,
      notes:          notes ?? this.notes,
      status:         status ?? this.status,
      createdBy:      createdBy ?? this.createdBy,
      createdAt:      createdAt ?? this.createdAt,
      updatedAt:      updatedAt ?? this.updatedAt,
      donorUsernames: donorUsernames ?? this.donorUsernames,
    );
  }

  bool get isOpen      => status == 'Open';
  bool get isFulfilled => status == 'Fulfilled';
  bool get isCancelled => status == 'Cancelled';
  bool get isUrgent    => urgency == 'Critical';

  // How many units have been donated = unitsRequired - remainingUnits
  int get unitsFulfilled => (unitsRequired - remainingUnits).clamp(0, unitsRequired);

  // Alias for cards/modals
  int get donorCount => donationsCount > 0 ? donationsCount : unitsFulfilled;

  // Progress 0.0 → 1.0
  double get fulfillmentProgress =>
      unitsRequired > 0
          ? (unitsFulfilled / unitsRequired).clamp(0.0, 1.0)
          : 0.0;

  /// Returns true if [username] has already donated to this requirement.
  bool hasDonatedBy(String username) =>
      username.isNotEmpty && donorUsernames.contains(username);
}
