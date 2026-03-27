class NotificationModel {
  final String id;
  final String username;
  final String type;
  final String title;
  final String message;
  final String bloodType;
  final String? requirementId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.username,
    this.type = 'requirement',
    required this.title,
    required this.message,
    this.bloodType = '',
    this.requirementId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id']?.toString() ?? '',
      username: json['username'] ?? '',
      type: json['type'] ?? 'requirement',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      bloodType: json['bloodType'] ?? '',
      requirementId: json['requirementId']?.toString(),
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      username: username,
      type: type,
      title: title,
      message: message,
      bloodType: bloodType,
      requirementId: requirementId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
