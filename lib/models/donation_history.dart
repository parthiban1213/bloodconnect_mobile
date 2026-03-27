// Shape returned by GET /api/my-donations:
// {
//   requirementId, patientName, hospital, location,
//   bloodType, unitsRequired, remainingUnits, status,
//   urgency, donatedAt, note
// }
class DonationHistory {
  final String id;
  final String requirementId;
  final String hospital;
  final String bloodType;
  final String patientName;
  final String location;
  final String urgency;
  final String status;
  final int unitsRequired;
  final int remainingUnits;
  final DateTime donatedAt;
  final String note;

  DonationHistory({
    this.id = '',
    required this.requirementId,
    required this.hospital,
    required this.bloodType,
    this.patientName = '',
    this.location = '',
    this.urgency = 'Medium',
    this.status = 'Open',
    this.unitsRequired = 1,
    this.remainingUnits = 0,
    required this.donatedAt,
    this.note = '',
  });

  factory DonationHistory.fromJson(Map<String, dynamic> json) {
    return DonationHistory(
      id:             json['_id']?.toString() ?? '',
      requirementId:  json['requirementId']?.toString() ?? '',
      hospital:       json['hospital']?.toString() ?? '',
      bloodType:      json['bloodType']?.toString() ?? '',
      patientName:    json['patientName']?.toString() ?? '',
      location:       json['location']?.toString() ?? '',
      urgency:        json['urgency']?.toString() ?? 'Medium',
      status:         json['status']?.toString() ?? 'Open',
      unitsRequired:  (json['unitsRequired'] as num?)?.toInt() ?? 1,
      remainingUnits: (json['remainingUnits'] as num?)?.toInt() ?? 0,
      donatedAt: json['donatedAt'] != null
          ? DateTime.tryParse(json['donatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      note: json['note']?.toString() ?? '',
    );
  }
}
