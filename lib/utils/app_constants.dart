class AppConstants {
  static const String baseUrl = 'https://hsblood.onrender.com/api';
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';

  static const List<String> bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  static const List<String> urgencyLevels = [
    'Critical', 'High', 'Medium', 'Low'
  ];

  static const List<String> requirementStatuses = [
    'Open', 'Fulfilled', 'Cancelled'
  ];

  static const List<String> infoCategories = [
    'Hospital', 'Ambulance', 'Blood Bank'
  ];
}
