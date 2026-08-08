import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/network/api_network_service.dart';
import '../../data/network/base_api_service.dart';
import '../../data/models/response_model/auth_response_model/verify_otp_response.dart';
import '../../utils/app_session.dart';
import '../../utils/notification_service.dart';
import '../../utils/custom_snackbar.dart';

class AuthController extends GetxController {
  static const String _googleWebClientId =
      '717480494085-f4m3ttcfcb3eflf79gkncjf9je0rirf7.apps.googleusercontent.com';

  late final GoogleSignIn googleSignIn = kIsWeb
      ? GoogleSignIn(clientId: _googleWebClientId)
      : GoogleSignIn(serverClientId: _googleWebClientId);

  // ✅ FIX: Use late and initialize in onInit to ensure we get the global instance
  late AuthRepository repository;

  var isLoading = false.obs;
  var isGoogleLoading = false.obs;
  var isLoggedIn = false.obs;
  final storage = GetStorage();
  var userData = Rxn<Map<String, dynamic>>();

  StreamSubscription<GoogleSignInAccount?>? _googleSignInSubscription;

  @override
  void onInit() {
    super.onInit();

    // ✅ Always use the global instance registered in main.dart
    final globalApiService = Get.find<BaseApiService>();
    repository = AuthRepository(globalApiService);

    isLoggedIn.value = AppSession.getLogin();
    var saved = storage.read('user_data');
    if (saved != null) {
      userData.value = Map<String, dynamic>.from(saved);
    }

    // Set initial token from session if available
    String? token = AppSession.getToken();
    if (token != null && token.isNotEmpty) {
      _updateGlobalToken(token);
    }
  }

  // ✅ Helper to update token in the shared service
  void _updateGlobalToken(String token) {
    final apiService = Get.find<BaseApiService>();
    if (apiService is NetworkApiService) {
      apiService.setToken(token);
    }
  }

  /// 🔄 Sync FCM and Fetch Notifications after Login
  void _syncNotificationsAfterLogin() {
    try {
      if (Get.isRegistered<NotificationService>()) {
        print("🔔 Syncing notifications and FCM token after login...");
        NotificationService.to.uploadToken();
        NotificationService.to.fetchNotifications();
      }
    } catch (e) {
      print("⚠️ Notification sync failed: $e");
    }
  }

  void setLoginStatus(bool status) async {
    isLoggedIn.value = status;
    await AppSession.setLogin(status);

    if (status) {
      // ✅ Fetch all notifications from API when user logs in
      _syncNotificationsAfterLogin();
    }
  }

  Future<bool> sendOtp(String identifier) async {
    isLoading.value = true;
    try {
      final response = await repository.sendOtp(identifier);
      String otpMessage = 'Your OTP has been sent successfully.';
      if (response.otp != null) {
        otpMessage = 'Your OTP is: ${response.otp}';
      }
      CustomSnackbar.show(
        title: 'OTP Generated',
        message: otpMessage,
        isSuccess: true,
      );
      print(response);
      return true;
    } catch (e) {
      CustomSnackbar.show(title: 'Error', message: e.toString(), isError: true);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<VerifyOtpResponse?> verifyOtp(String phoneNumber, String otp) async {
    isLoading.value = true;
    try {
      final response = await repository.verifyOtp(phoneNumber, otp);
      if (response != null && response.success) {
        if (response.token != null) {
          await AppSession.setToken(response.token!);
          _updateGlobalToken(response.token!); // ✅ Sync token to global service
        }

        if (response.user != null) {
          userData.value = response.user;
          await storage.write('user_data', response.user);
        }

        // ✅ Fix: Set login status if NOT a new user (Existing user is now logged in)
        if (!response.isNewUser) {
          setLoginStatus(true);
        }

        if (phoneNumber.contains('@')) {
          await _syncNumericPhoneIfNeeded(response.user);
        }

        return response;
      }
      return null;
    } catch (e) {
      CustomSnackbar.show(title: 'Error', message: e.toString(), isError: true);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updatePhoneNumber(String phone) async {
    try {
      // Use a local loading state if needed, but don't block the global one if it's a silent sync
      final response = await repository.updateProfile(phone: phone);
      if (response != null) {
        await getProfile(); // Refresh user data to get updated phone
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Update Phone Error: $e");
      return false;
    }
  }

  Future<VerifyOtpResponse?> signInWithGoogle([
    GoogleSignInAccount? authenticatedUser,
  ]) async {
    isGoogleLoading.value = true;
    try {
      final GoogleSignInAccount? googleUser =
          authenticatedUser ?? await googleSignIn.signIn();

      if (googleUser == null) {
        isGoogleLoading.value = false;
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        CustomSnackbar.show(
          title: 'Error',
          message: 'Failed to get ID Token from Google',
          isError: true,
        );
        return null;
      }

      final response = await repository.googleLogin(idToken);
      if (response != null && response.success) {
        if (response.token != null && response.token!.isNotEmpty) {
          await AppSession.setToken(response.token!);
          _updateGlobalToken(response.token!);
        } else {
          print("⚠️ Google Login Success but NO TOKEN returned");
        }

        if (response.user != null) {
          userData.value = response.user;
          await storage.write('user_data', response.user);
        }
        setLoginStatus(true);

        return response;
      } else {
        print("❌ Google Login Failed: ${response?.message}");
      }
      return null;
    } catch (e) {
      final String errorMessage = e.toString();
      final bool isPeopleApiDisabled =
          errorMessage.contains('people.googleapis.com') ||
          errorMessage.contains('People API has not been used');

      CustomSnackbar.show(
        title: 'Error',
        message: isPeopleApiDisabled
            ? 'Google People API is disabled for this project. Enable it in '
                  'Google Cloud Console, wait a few minutes, then try again.'
            : 'Google sign-in failed. Please try again.',
        isError: true,
      );
      return null;
    } finally {
      isGoogleLoading.value = false;
    }
  }

  @override
  void onClose() {
    _googleSignInSubscription?.cancel();
    super.onClose();
  }

  Future<bool> websiteLogin(String token) async {
    isLoading.value = true;
    try {
      await AppSession.setToken(token);
      _updateGlobalToken(token);

      final response = await repository.websiteLogin();
      if (response != null && response.success) {
        if (response.user != null) {
          userData.value = response.user;
          await storage.write('user_data', response.user);
        }
        setLoginStatus(true);
        //  FacebookEventsService.logLogin(method: "website");
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Website Login Error: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateAndSaveProfile({
    required String name,
    required String email,
    required String phone,
    String? imagePath,
  }) async {
    try {
      isLoading.value = true;
      final response = await repository.createProfile(
        phone: phone,
        name: name,
        profileImage: imagePath,
      );

      if (response != null) {
        String? token = response['token'];
        if (token != null) {
          await AppSession.setToken(token);
          _updateGlobalToken(token); // ✅ Sync token to global service
        }

        userData.value =
            response['user'] ?? {"name": name, "email": email, "phone": phone};
        await storage.write('user_data', userData.value);

        // ✅ User is fully registered and logged in now
        setLoginStatus(true);
        return true;
      }
      return false;
    } catch (e) {
      if (e.toString().contains("Profile already completed")) {
        setLoginStatus(true);
        return true;
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getProfile() async {
    try {
      final response = await repository.getProfile();
      if (response != null && response['user'] != null) {
        final user = Map<String, dynamic>.from(response['user']);

        // 🚫 Block check: if user is blocked, log them out
        if (user['isBlocked'] == true) {
          await logout();
          CustomSnackbar.show(
            title: "Account Blocked",
            message: "Your account has been blocked. Please contact support.",
            isError: true,
          );
          return;
        }

        userData.value = user;
        await storage.write('user_data', userData.value);
      }
    } catch (e) {
      print("❌ Error fetching profile: $e");
    }
  }

  Future<void> logout() async {
    await AppSession.clearSession();
    await storage.remove('user_data');
    userData.value = null;
    isLoggedIn.value = false;
    _updateGlobalToken(""); // Clear token in network service

    // Clear notifications locally on logout
    if (Get.isRegistered<NotificationService>()) {
      NotificationService.to.clearNotifications();
    }
  }

  bool isPhoneMissing(Map<String, dynamic>? user) {
    String currentPhone = user?['phone']?.toString() ?? "";

    return currentPhone.isEmpty ||
        currentPhone.contains(RegExp(r'[a-zA-Z]')) ||
        currentPhone.length != 10;
  }

  Future<bool> generateAndSaveDummyPhone() async {
    try {
      String uniqueDummy =
          "9${DateTime.now().millisecondsSinceEpoch.toString().substring(4, 13)}";
      debugPrint("🛠 Generating dummy phone: $uniqueDummy");
      return await updatePhoneNumber(uniqueDummy);
    } catch (e) {
      debugPrint("⚠️ Failed to generate dummy phone: $e");
      return false;
    }
  }

  Future<void> _syncNumericPhoneIfNeeded(Map<String, dynamic>? user) async {
    try {
      if (isPhoneMissing(user)) {
        debugPrint(
          "🛠 Syncing numeric dummy phone for numeric-only API requirements...",
        );
        await generateAndSaveDummyPhone();
      }
    } catch (e) {
      debugPrint("⚠️ Failed to sync numeric phone: $e");
    }
  }
}
