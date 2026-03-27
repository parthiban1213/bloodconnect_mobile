class InfoEntry {
  final String id;
  final String category;
  final String name;
  final String phone;
  final String address;
  final String area;
  final String notes;
  final bool available24h;
  final double? lat;
  final double? lng;
  final DateTime createdAt;

  InfoEntry({
    required this.id,
    required this.category,
    required this.name,
    required this.phone,
    this.address = '',
    this.area = '',
    this.notes = '',
    this.available24h = false,
    this.lat,
    this.lng,
    required this.createdAt,
  });

  factory InfoEntry.fromJson(Map<String, dynamic> json) {
    return InfoEntry(
      id: json['_id']?.toString() ?? '',
      category: json['category'] ?? 'Hospital',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      area: json['area'] ?? '',
      notes: json['notes'] ?? '',
      available24h: json['available24h'] ?? false,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
