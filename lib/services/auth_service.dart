import '../models/user_model.dart';
import '../utils/api_exception.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client = ApiClient.instance;

  // ── Username / Password ─────────────────────────────────────
  Future<({String token, UserModel user})> login(
      String username, String password) async {
    final res = await _client.post('/auth/login', data: {
      'username': username.trim(),
      'password': password,
    });
    final token = res['token'] as String;
    final user = UserModel.fromJson(res['user'] as Map<String, dynamic>);
    await _client.setToken(token);
    return (token: token, user: user);
  }

  // ── OTP: send (login — requires existing account) ───────────
  Future<bool> sendOtp(String mobile) async {
    final res = await _client.post('/auth/otp/send', data: {'mobile': mobile});
    print('[AuthService] sendOtp response: $res');
    final isExistingUser  = res['isExistingUser']  == true;
    final isExistingDonor = res['isExistingDonor'] == true;
    final success         = res['success']          == true;
    final sent            = res['sent']             == true;
    final otpSent         = res['otpSent']          == true;
    if (!isExistingUser && !isExistingDonor && !success && !sent && !otpSent) {
      throw OtpNoAccountException();
    }
    return true;
  }

  // ── OTP: send (register — server blocks if mobile already exists) ─────
  Future<void> sendOtpForRegister(String mobile) async {
    try {
      final res = await _client.post('/auth/otp/send', data: {
        'mobile':  mobile,
        'purpose': 'register',
      });
      print('[AuthService] sendOtpForRegister response: $res');
    } on ApiException catch (e) {
      if (e.statusCode == 409) throw MobileAlreadyExistsException();
      rethrow;
    }
  }

  // ── OTP: pre-verify for register ────────────────────────────
  Future<void> verifyRegisterOtp({
    required String mobile,
    required String otp,
  }) async {}

  // ── OTP: register new HS Employee (with custom username) ────
  Future<({String token, UserModel user})> registerDirect({
    required String mobile,
    required String otp,
    required String username,
    required String firstName,
    required String lastName,
    required String bloodType,
    required String email,
    String? address,
    DateTime? lastDonationDate,
  }) async {
    final res = await _client.post('/auth/register-direct', data: {
      'mobile':    mobile,
      'otp':       otp,
      'username':  username,
      'firstName': firstName,
      'lastName':  lastName,
      'bloodType': bloodType,
      'email':     email,
      if (address != null && address.isNotEmpty) 'address': address,
      if (lastDonationDate != null)
        'lastDonationDate': lastDonationDate.toIso8601String(),
    });
    final token = res['token'] as String;
    final user  = UserModel.fromJson(res['user'] as Map<String, dynamic>);
    await _client.setToken(token);
    return (token: token, user: user);
  }

  // ── OTP: register new HS Employee ───────────────────────────
  Future<({String token, UserModel user})> registerWithOtp({
    required String mobile,
    required String otp,
    required String firstName,
    required String lastName,
    required String bloodType,
    String? email,
    String? address,
    required bool isAvailable,
    DateTime? lastDonationDate,
  }) async {
    final res = await _client.post('/auth/otp/register', data: {
      'mobile':    mobile,
      'otp':       otp,
      'firstName': firstName,
      'lastName':  lastName,
      'bloodType': bloodType,
      if (email   != null && email.isNotEmpty)   'email':   email,
      if (address != null && address.isNotEmpty) 'address': address,
      'isAvailable': isAvailable,
      if (lastDonationDate != null)
        'lastDonationDate': lastDonationDate.toIso8601String(),
    });
    final token = res['token'] as String;
    final user  = UserModel.fromJson(res['user'] as Map<String, dynamic>);
    await _client.setToken(token);
    return (token: token, user: user);
  }

  // ── OTP: verify & login ─────────────────────────────────────
  Future<({String token, UserModel user})> loginWithOtp(
      String mobile, String otp) async {
    final res = await _client.post('/auth/otp/login', data: {
      'mobile': mobile,
      'otp':    otp,
    });
    final token = res['token'] as String;
    final user  = UserModel.fromJson(res['user'] as Map<String, dynamic>);
    await _client.setToken(token);
    return (token: token, user: user);
  }

  // ── Profile helpers ─────────────────────────────────────────
  Future<UserModel> getMe() async {
    final res = await _client.get('/auth/me');
    return UserModel.fromJson(res['user'] as Map<String, dynamic>);
  }

  Future<UserModel> getProfile() async {
    final res = await _client.get('/auth/profile');
    return UserModel.fromJson(res['user'] as Map<String, dynamic>);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final res = await _client.put('/auth/profile', data: data);
    return UserModel.fromJson(res['user'] as Map<String, dynamic>);
  }

  Future<void> updateAvailability(bool isAvailable) async {
    await _client.post('/auth/availability', data: {'isAvailable': isAvailable});
  }

  Future<void> changePassword(String newPassword, String confirmPassword) async {
    await _client.post('/auth/change-password', data: {
      'newPassword':     newPassword,
      'confirmPassword': confirmPassword,
    });
  }

  Future<void> forgotPassword({
    required String username,
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _client.post('/auth/forgot-password', data: {
      'username':     username.trim(),
      'email':        email.trim(),
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
  }

  // ── Delete own account ──────────────────────────────────────
  // Mirrors the web: DELETE /auth/account
  // Server removes the user, their linked donor record, and all notifications.
  // Admins are blocked server-side (403) so no extra guard needed here.
  Future<void> deleteAccount() async {
    await _client.delete('/auth/account');
  }

  Future<void> logout() async => _client.clearToken();

  Future<bool> isLoggedIn() async => (await _client.getToken()) != null;
}

/// Thrown when the mobile number has no registered account.
class OtpNoAccountException implements Exception {
  final String message =
      'No account found for this mobile. Please contact your administrator.';
  @override
  String toString() => message;
}
