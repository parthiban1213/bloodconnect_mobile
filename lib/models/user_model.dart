class UserModel {
  final String id;
  final String username;
  final String role;
  final String email;
  final String bloodType;
  final bool isAvailable;
  final String address;
  final DateTime? lastDonationDate;
  final String? mobile;
  final String? firstName;
  final String? lastName;
  final int? donationCount;

  UserModel({
    required this.id,
    required this.username,
    required this.role,
    this.email = '',
    this.bloodType = '',
    this.isAvailable = true,
    this.address = '',
    this.lastDonationDate,
    this.mobile,
    this.firstName,
    this.lastName,
    this.donationCount,
  });

  String get displayName {
    final fn = firstName ?? '';
    final ln = lastName ?? '';
    if (fn.isNotEmpty || ln.isNotEmpty) return '$fn $ln'.trim();
    return username;
  }

  String get initials {
    final name = displayName;
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return username.isNotEmpty ? username[0].toUpperCase() : '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? 'user',
      email: json['email'] ?? '',
      bloodType: json['bloodType'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      address: json['address'] ?? '',
      lastDonationDate: json['lastDonationDate'] != null
          ? DateTime.tryParse(json['lastDonationDate'].toString())
          : null,
      mobile: json['mobile']?.toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      donationCount: json['donationCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'username': username,
    'role': role,
    'email': email,
    'bloodType': bloodType,
    'isAvailable': isAvailable,
    'address': address,
    'lastDonationDate': lastDonationDate?.toIso8601String(),
    'mobile': mobile,
    'firstName': firstName,
    'lastName': lastName,
  };

  UserModel copyWith({
    String? id,
    String? username,
    String? role,
    String? email,
    String? bloodType,
    bool? isAvailable,
    String? address,
    DateTime? lastDonationDate,
    String? mobile,
    String? firstName,
    String? lastName,
    int? donationCount,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      role: role ?? this.role,
      email: email ?? this.email,
      bloodType: bloodType ?? this.bloodType,
      isAvailable: isAvailable ?? this.isAvailable,
      address: address ?? this.address,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      mobile: mobile ?? this.mobile,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      donationCount: donationCount ?? this.donationCount,
    );
  }
}
