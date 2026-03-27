import '../models/user_model.dart';
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

  // ── OTP: send ───────────────────────────────────────────────
  /// Returns true if the OTP was sent successfully.
  Future<bool> sendOtp(String mobile) async {
    final res = await _client.post('/auth/otp/send', data: {'mobile': mobile});

    // DEBUG: print the full response so you can see what your backend returns.
    // Remove this line once OTP flow is working correctly.
    print('[AuthService] sendOtp response: $res');

    // Accept the OTP as sent if ANY of these common success indicators are present.
    // Adjust the condition below to match your backend's actual response shape.
    final isExistingUser = res['isExistingUser'] == true;
    final isExistingDonor = res['isExistingDonor'] == true;
    final success = res['success'] == true;
    final sent = res['sent'] == true;
    final otpSent = res['otpSent'] == true;

    if (!isExistingUser && !isExistingDonor && !success && !sent && !otpSent) {
      throw OtpNoAccountException();
    }

    return true;
  }

  // ── OTP: verify & login ─────────────────────────────────────
  Future<({String token, UserModel user})> loginWithOtp(
      String mobile, String otp) async {
    final res = await _client.post('/auth/otp/login', data: {
      'mobile': mobile,
      'otp': otp,
    });
    final token = res['token'] as String;
    final user = UserModel.fromJson(res['user'] as Map<String, dynamic>);
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
    await _client
        .post('/auth/availability', data: {'isAvailable': isAvailable});
  }

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    await _client.post('/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> forgotPassword({
    required String username,
    required String email,
    required String newPassword,
  }) async {
    await _client.post('/auth/forgot-password', data: {
      'username': username.trim(),
      'email': email.trim(),
      'newPassword': newPassword,
    });
  }

  Future<void> logout() async {
    await _client.clearToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await _client.getToken();
    return token != null;
  }
}

/// Thrown when the mobile number has no registered account.
class OtpNoAccountException implements Exception {
  final String message =
      'No account found for this mobile. Please contact your administrator.';
  @override
  String toString() => message;
}
