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

  // Start with isCheckingAuth: true immediately so the router redirect never
  // sees a false/false state before _checkAuth runs. Without this, there is a
  // one-frame window where isCheckingAuth is false AND isLoggedIn is false,
  // which can confuse the router into thinking auth is settled when it isn't.
  AuthViewModel() : super(const AuthState(isCheckingAuth: true)) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    state = state.copyWith(isLoading: true, isCheckingAuth: true);
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authService.getProfile();
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
    } on UnauthorizedException {
      await _authService.logout();
      state = state.copyWith(isLoading: false, isCheckingAuth: false, isLoggedIn: false);
    } on NetworkException {
      final hasToken = await _authService.isLoggedIn();
      state = state.copyWith(
        isLoading: false,
        isCheckingAuth: false,
        isLoggedIn: hasToken,
      );
    } catch (_) {
      final hasToken = await _authService.isLoggedIn();
      state = state.copyWith(
        isLoading: false,
        isCheckingAuth: false,
        isLoggedIn: hasToken,
      );
    }
  }

  Future<int> _fetchDonationCount() async {
    try {
      final donations = await _reqService.getMyDonations();
    // Only count donations the requester has marked as Completed.
    // Pending pledges do not increment the donated count.
      return donations.where((d) => d.isCompleted).length;
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
    } on UnauthorizedException {
      state = state.copyWith(
        isLoading: false,
        error: 'Invalid username or password.',
      );
      return false;
    } on ApiException catch (e) {
      final msg = (e.statusCode == 401)
          ? 'Invalid username or password.'
          : e.message;
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Login failed. Please try again.');
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

  Future<bool> changePassword(String newPassword, String confirmPassword) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.changePassword(newPassword, confirmPassword);
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
    required String confirmPassword
  }) async {
    await _authService.forgotPassword(
        username: username, email: email, newPassword: newPassword, confirmPassword: confirmPassword);
  }

  void clearError() => state = state.copyWith(clearError: true);

  Future<void> refreshProfile() async {
    if (state.user == null) {
      state = state.copyWith(isLoading: true);
    }
    try {
      final user  = await _authService.getProfile();
      final count = await _fetchDonationCount();
      // Always use the server's lastDonationDate — never fall back to the
      // previously cached value. The server is the single source of truth.
      // Falling back to state.user?.lastDonationDate caused cross-user
      // contamination when logging out and back in as a different user.
      state = state.copyWith(
        isLoading: false,
        user: user.copyWith(donationCount: count),
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loginFromRegistration(String token, UserModel user) async {
    state = state.copyWith(
      isLoading:      false,
      isLoggedIn:     true,
      user:           user.copyWith(donationCount: 0),
      sessionExpired: false,
      clearError:     true,
    );
  }

  // ── Session validation on app resume ───────────────────────
  // Called by main.dart's WidgetsBindingObserver whenever the app comes back
  // to the foreground. Silently re-validates the stored token against the
  // server. If the account was deleted from the backend (401/404) the token
  // is cleared and auth state resets — the router then redirects to /login.
  // Skipped if already loading or not logged in (no token to validate).
  Future<void> validateSessionOnResume() async {
    if (!state.isLoggedIn) return;
    if (state.isLoading || state.isCheckingAuth) return;
    try {
      final user  = await _authService.getProfile();
      final count = await _fetchDonationCount();
      // Always trust the server's lastDonationDate — no local fallback.
      state = state.copyWith(
        user: user.copyWith(donationCount: count),
      );
    } on UnauthorizedException {
      // Token rejected — account deleted or revoked on the backend
      await _authService.logout();
      state = const AuthState();
    } on NetworkException {
      // No connectivity on resume — keep existing session, try again next time
    } catch (_) {
      // Any other transient error — don't log the user out
    }
  }

    // ── Delete own account ──────────────────────────────────────
  // Calls DELETE /auth/account. On success, clears local token and resets
  // auth state (same as logout) so the router redirects to /login.
  // Returns true on success, false on any error (caller shows snackbar).
  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.deleteAccount();
      // Clear stored token and wipe state — same path as logout
      await _authService.logout();
      state = const AuthState();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not delete account. Please try again.',
      );
      return false;
    }
  }
}

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel();
});
