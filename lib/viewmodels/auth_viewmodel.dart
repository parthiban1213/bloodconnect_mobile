import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/requirements_service.dart';
import '../utils/api_exception.dart';

enum LoginMethod { otp, password }
enum OtpStep { enterMobile, enterCode }

class AuthState {
  final bool isLoading;
  final bool isCheckingAuth; // true only during startup _checkAuth, not login
  final bool isLoggedIn;
  final UserModel? user;
  final String? error;
  final OtpStep otpStep;
  final String otpMobile;
  final bool otpSending;
  final bool otpVerifying;
  final bool sessionExpired;

  const AuthState({
    this.isLoading      = false,
    this.isCheckingAuth = false,
    this.isLoggedIn     = false,
    this.user,
    this.error,
    this.otpStep      = OtpStep.enterMobile,
    this.otpMobile    = '',
    this.otpSending   = false,
    this.otpVerifying = false,
    this.sessionExpired = false,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isCheckingAuth,
    bool? isLoggedIn,
    UserModel? user,
    String? error,
    bool clearError = false,
    OtpStep? otpStep,
    String? otpMobile,
    bool? otpSending,
    bool? otpVerifying,
    bool? sessionExpired,
  }) {
    return AuthState(
      isLoading:      isLoading ?? this.isLoading,
      isCheckingAuth: isCheckingAuth ?? this.isCheckingAuth,
      isLoggedIn:     isLoggedIn ?? this.isLoggedIn,
      user:         user ?? this.user,
      error:        clearError ? null : (error ?? this.error),
      otpStep:      otpStep ?? this.otpStep,
      otpMobile:    otpMobile ?? this.otpMobile,
      otpSending:   otpSending ?? this.otpSending,
      otpVerifying: otpVerifying ?? this.otpVerifying,
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();
  final RequirementsService _reqService = RequirementsService();

  AuthViewModel() : super(const AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    state = state.copyWith(isLoading: true, isCheckingAuth: true);
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authService.getProfile(); // getProfile returns firstName+lastName+bloodType
        // Compute donationCount from /my-donations on startup
        final count = await _fetchDonationCount();
        state = state.copyWith(
          isLoading: false,
          isCheckingAuth: false,
          isLoggedIn: true,
          user: user.copyWith(donationCount: count),
        );
      } else {
        state = state.copyWith(isLoading: false, isCheckingAuth: false, isLoggedIn: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, isCheckingAuth: false, isLoggedIn: false);
    }
  }

  /// Fetch the number of donations made by this user from /my-donations
  Future<int> _fetchDonationCount() async {
    try {
      final donations = await _reqService.getMyDonations();
      return donations.length;
    } catch (_) {
      return state.user?.donationCount ?? 0;
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authService.login(username, password);
      final count  = await _fetchDonationCount();
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        user: result.user.copyWith(donationCount: count),
        sessionExpired: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Login failed: ${e.toString()}');
      return false;
    }
  }

  Future<bool> sendOtp(String mobile) async {
    state = state.copyWith(otpSending: true, clearError: true);
    try {
      await _authService.sendOtp(mobile);
      state = state.copyWith(
          otpSending: false, otpMobile: mobile, otpStep: OtpStep.enterCode);
      return true;
    } on OtpNoAccountException catch (e) {
      state = state.copyWith(otpSending: false, error: e.message);
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(otpSending: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
          otpSending: false, error: 'Could not send OTP: ${e.toString()}');
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    state = state.copyWith(otpVerifying: true, clearError: true);
    try {
      final result = await _authService.loginWithOtp(state.otpMobile, otp);
      final count  = await _fetchDonationCount();
      state = state.copyWith(
        otpVerifying: false,
        isLoggedIn: true,
        user: result.user.copyWith(donationCount: count),
        sessionExpired: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(otpVerifying: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
          otpVerifying: false, error: 'Verification failed: ${e.toString()}');
      return false;
    }
  }

  void resetOtpFlow() {
    state = state.copyWith(
        otpStep: OtpStep.enterMobile, otpMobile: '', clearError: true);
  }

  Future<void> handleSessionExpired() async {
    await _authService.logout();
    state = const AuthState(sessionExpired: true);
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }

  Future<bool> updateAvailability(bool isAvailable) async {
    try {
      await _authService.updateAvailability(isAvailable);
      if (state.user != null) {
        state = state.copyWith(
            user: state.user!.copyWith(isAvailable: isAvailable));
      }
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _authService.updateProfile(data);
      state = state.copyWith(isLoading: false, user: updated);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.changePassword(currentPassword, newPassword);
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    }
  }

  Future<void> forgotPassword({
    required String username,
    required String email,
    required String newPassword,
  }) async {
    await _authService.forgotPassword(
        username: username, email: email, newPassword: newPassword);
  }

  void clearError() => state = state.copyWith(clearError: true);

  /// Persists [donationDate] to the server via PUT /auth/profile so it
  /// survives app restarts and re-logins. Also updates local state immediately.
  /// Awaited before refreshProfile() in the donate flow so the server has the
  /// value before we re-fetch the profile.
  Future<void> persistLastDonationDate(DateTime donationDate) async {
    // Update local state immediately (replaces the old recordDonationNow call)
    if (state.user != null) {
      state = state.copyWith(
        user: state.user!.copyWith(lastDonationDate: donationDate),
      );
    }
    try {
      await _authService.updateProfile({
        'lastDonationDate': donationDate.toIso8601String(),
      });
    } catch (_) {
      // Non-critical — local optimistic value is already set;
      // the profile screen will still show the correct date this session.
    }
  }

  /// Re-fetches profile from server — called on ProfileScreen mount and after donate.
  /// Sets isLoading so the screen can show a shimmer on first load.
  Future<void> refreshProfile() async {
    // Only show loading spinner if we have no user data yet
    if (state.user == null) {
      state = state.copyWith(isLoading: true);
    }
    try {
      final user  = await _authService.getProfile();
      final count = await _fetchDonationCount();
      // Preserve the optimistically-set lastDonationDate if the server returns
      // null (e.g. the write hasn't propagated yet). Once the server returns a
      // real date, that takes over naturally.
      final resolvedLastDonation =
          user.lastDonationDate ?? state.user?.lastDonationDate;
      state = state.copyWith(
        isLoading: false,
        user: user.copyWith(
          donationCount: count,
          lastDonationDate: resolvedLastDonation,
        ),
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      // Non-critical — keep existing user data if refresh fails
      state = state.copyWith(isLoading: false);
    }
  }
  // ── Called after successful OTP registration ────────────────
  /// Hydrates the auth state directly from a registration result
  /// (token already stored by AuthService.registerWithOtp).
  Future<void> loginFromRegistration(String token, UserModel user) async {
    final count = await _fetchDonationCount();
    state = state.copyWith(
      isLoading:      false,
      isLoggedIn:     true,
      user:           user.copyWith(donationCount: count),
      sessionExpired: false,
      clearError:     true,
    );
  }

}

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel();
});
