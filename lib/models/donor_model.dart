class DonorModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String phone;
  final String address;
  final String city;
  final String country;
  final String bloodType;
  final DateTime? lastDonationDate;
  final bool isAvailable;
  final DateTime createdAt;

  DonorModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.phone,
    this.address = '',
    this.city = '',
    this.country = '',
    required this.bloodType,
    this.lastDonationDate,
    this.isAvailable = true,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final parts = [firstName, lastName].where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory DonorModel.fromJson(Map<String, dynamic> json) {
    return DonorModel(
      id: json['_id']?.toString() ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email']?.toString(),
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      bloodType: json['bloodType'] ?? '',
      lastDonationDate: json['lastDonationDate'] != null
          ? DateTime.tryParse(json['lastDonationDate'].toString())
          : null,
      isAvailable: json['isAvailable'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
