import 'package:get/get.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/services/social_auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../routes/app_routes.dart';

class SettingsController extends GetxController {
  final ApiClient apiClient;
  final StorageService storageService;

  SettingsController({
    required this.apiClient,
    required this.storageService,
  });

  final isBiometricEnabled = false.obs;
  final isLoading = false.obs;
  final currentTimezone = 'UTC'.obs;

  // Connected Accounts State
  final isGoogleLinked = false.obs;
  final googleEmail = RxnString();
  final isAppleAvailable = false.obs;
  final isAppleLinked = false.obs;
  final appleEmail = RxnString();
  final isAppleRegistered = false.obs;
  final isBindingGoogle = false.obs;
  final isBindingApple = false.obs;
  final isUnbindingApple = false.obs;

  SyncService get syncService => Get.find<SyncService>();
  Map<String, dynamic>? get user => storageService.user;

  int get localTransactionCount => storageService.cachedTransactions.length;
  int get localCategoryCount => storageService.cachedCategories.length;

  @override
  void onInit() {
    super.onInit();
    isBiometricEnabled.value = storageService.isBiometricEnabled;
    currentTimezone.value = user?['timezone']?.toString() ?? 'UTC';

    _checkAppleAvailability();

    // Populate connected accounts immediately from cached user data if available
    _populateFromUserData(user);

    _fetchUserSettings();
  }

  Future<void> _checkAppleAvailability() async {
    isAppleAvailable.value = await SocialAuthService.isAppleSignInAvailable();
  }

  void _populateFromUserData(Map<String, dynamic>? data) {
    if (data == null) return;

    if (data['timezone'] != null) {
      currentTimezone.value = data['timezone'].toString();
    }

    final appleId = data['apple_id']?.toString();
    final googleId = data['google_id']?.toString();
    final email = data['email']?.toString();
    final isAppleReg = data['is_apple_registered'] == true ||
        ((appleId != null && appleId.isNotEmpty) &&
            (data['password'] == null ||
                (email != null && email.contains('privaterelay.appleid.com'))));

    isAppleRegistered.value = isAppleReg;

    final hasApple = (data['is_apple_linked'] == true) ||
        (appleId != null && appleId.isNotEmpty);
    isAppleLinked.value = hasApple;
    appleEmail.value = data['apple_email']?.toString() ?? (hasApple ? email : null);

    final hasGoogle = (data['is_google_linked'] == true) ||
        (googleId != null && googleId.isNotEmpty) ||
        (!isAppleReg && email != null && email.isNotEmpty);
    isGoogleLinked.value = hasGoogle;
    googleEmail.value = data['google_email']?.toString() ?? (hasGoogle ? email : null);
  }

  Future<void> _fetchUserSettings() async {
    try {
      final res = await apiClient.get(ApiEndpoints.userSettings);
      final body = res.data;
      final data = (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>)
          ? body['data'] as Map<String, dynamic>
          : (body is Map<String, dynamic> && body['body'] is Map<String, dynamic>)
              ? body['body'] as Map<String, dynamic>
              : (body is Map<String, dynamic> ? body : null);

      if (data != null) {
        _populateFromUserData(data);

        // Update local cached user profile
        if (storageService.user != null) {
          final updated = Map<String, dynamic>.from(storageService.user!);
          updated.addAll(data);
          await storageService.saveUser(updated);
        }
      } else {
        await _fetchUserProfileFallback();
      }
    } catch (e) {
      LoggerService.w('Failed to fetch user settings: $e', tag: 'SettingsController');
      await _fetchUserProfileFallback();
    }
  }

  Future<void> _fetchUserProfileFallback() async {
    try {
      final res = await apiClient.get(ApiEndpoints.userMe);
      final body = res.data;
      final data = (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>)
          ? body['data'] as Map<String, dynamic>
          : (body is Map<String, dynamic> ? body : null);

      if (data != null) {
        _populateFromUserData(data);
        if (storageService.user != null) {
          final updated = Map<String, dynamic>.from(storageService.user!);
          updated.addAll(data);
          await storageService.saveUser(updated);
        }
      }
    } catch (e) {
      LoggerService.w('Failed to fallback to user profile: $e', tag: 'SettingsController');
    }
  }

  Future<void> bindGoogle() async {
    try {
      AppHaptics.selection();
      isBindingGoogle.value = true;
      final result = await SocialAuthService.signInWithGoogle();
      if (result == null) return;

      final res = await apiClient.post(
        ApiEndpoints.bindGoogle,
        data: {
          if (result.serverAuthCode != null && result.serverAuthCode!.isNotEmpty)
            'code': result.serverAuthCode,
          if (result.idToken != null && result.idToken!.isNotEmpty)
            'credential': result.idToken,
        },
      );

      final body = res.data;
      final data = (body is Map && body['data'] is Map) ? body['data'] : body;
      isGoogleLinked.value = true;
      if (data != null && data['google_email'] != null) {
        googleEmail.value = data['google_email'].toString();
      } else {
        googleEmail.value = result.email;
      }

      AppHaptics.success();
      SnackbarService.success('Google account connected successfully! 🎉');
    } catch (e) {
      if (!AppErrorHandler.isUserCancelled(e)) {
        AppErrorHandler.handle(
          e,
          fallback: 'Failed to connect Google account',
          tag: 'SettingsController',
        );
      }
    } finally {
      isBindingGoogle.value = false;
    }
  }

  Future<void> bindApple() async {
    if (!isAppleAvailable.value) {
      SnackbarService.error(
        'Apple Sign-In is only available on supported Apple devices.',
        title: 'Not Supported',
      );
      return;
    }

    try {
      AppHaptics.selection();
      isBindingApple.value = true;
      final result = await SocialAuthService.signInWithApple();
      if (result == null) return;

      final res = await apiClient.post(
        ApiEndpoints.bindApple,
        data: {
          'identityToken': result.identityToken,
          'email': result.email,
          'userIdentifier': result.userIdentifier,
        },
      );

      final body = res.data;
      final data = (body is Map && body['data'] is Map) ? body['data'] : body;
      isAppleLinked.value = true;
      if (data != null && data['apple_email'] != null) {
        appleEmail.value = data['apple_email'].toString();
      } else {
        appleEmail.value = result.email;
      }

      AppHaptics.success();
      SnackbarService.success('Apple ID linked successfully! 🍏');
    } catch (e) {
      if (!AppErrorHandler.isUserCancelled(e)) {
        AppErrorHandler.handle(
          e,
          fallback: 'Failed to connect Apple ID',
          tag: 'SettingsController',
        );
      }
    } finally {
      isBindingApple.value = false;
    }
  }

  Future<void> unbindApple() async {
    if (isAppleRegistered.value && !isGoogleLinked.value) {
      SnackbarService.error(
        'Cannot unbind Apple ID. Please link your Google account first to prevent account lockout.',
      );
      return;
    }

    try {
      AppHaptics.selection();
      isUnbindingApple.value = true;
      await apiClient.post(ApiEndpoints.unbindApple);

      isAppleLinked.value = false;
      appleEmail.value = null;

      AppHaptics.success();
      SnackbarService.success('Apple ID unlinked successfully');
    } catch (e) {
      AppErrorHandler.handle(
        e,
        fallback: 'Failed to unlink Apple ID',
        tag: 'SettingsController',
      );
    } finally {
      isUnbindingApple.value = false;
    }
  }

  Future<void> updateTimezone(String newTimezone) async {
    try {
      AppHaptics.selection();
      isLoading.value = true;
      await apiClient.patch(
        ApiEndpoints.userTimezone,
        data: {'timezone': newTimezone},
      );
      currentTimezone.value = newTimezone;

      // Update storage user if exists
      if (storageService.user != null) {
        final updatedUser = Map<String, dynamic>.from(storageService.user!);
        updatedUser['timezone'] = newTimezone;
        await storageService.saveUser(updatedUser);
      }

      AppHaptics.success();
      SnackbarService.success('Timezone updated to $newTimezone');
    } catch (e) {
      AppErrorHandler.handle(
        e,
        fallback: 'Failed to update timezone',
        tag: 'SettingsController',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> triggerManualSync() async {
    AppHaptics.medium();
    await syncService.syncNow();
  }

  Future<void> triggerFullResync() async {
    AppHaptics.heavy();
    await syncService.fullResync();
  }

  void toggleBiometric(bool val) {
    AppHaptics.selection();
    isBiometricEnabled.value = val;
    storageService.setBiometricEnabled(val);
    SnackbarService.success(val ? 'Biometric lock enabled' : 'Biometric lock disabled');
  }

  Future<void> logout() async {
    try {
      AppHaptics.heavy();
      if (syncService.isOnline.value) {
        await apiClient.post(ApiEndpoints.logout);
      }
    } catch (e) {
      LoggerService.w('Logout API error: $e', tag: 'SettingsController');
    } finally {
      // Clear auth tokens and user profile
      await storageService.clearAuth();
      // Clear cached data and sync queue so subsequent logins start completely clean
      await storageService.saveCachedTransactions([]);
      await storageService.saveCachedCategories([]);
      await storageService.saveCachedDashboard({});
      await storageService.saveSyncQueue([]);
      syncService.pendingCount.value = 0;

      Get.offAllNamed(Routes.login);
      SnackbarService.success('Successfully logged out');
    }
  }

  Future<bool> deleteAccount() async {
    if (!syncService.isOnline.value) {
      SnackbarService.error(
        'Cannot delete account while offline. Please connect to the internet to delete your account.',
        title: 'Offline',
      );
      return false;
    }

    try {
      AppHaptics.heavy();
      isLoading.value = true;
      final response = await apiClient.delete(ApiEndpoints.deleteAccount);
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Clear all local auth, caches, and sync queue
        await storageService.clearAuth();
        await storageService.saveCachedTransactions([]);
        await storageService.saveCachedCategories([]);
        await storageService.saveCachedDashboard({});
        await storageService.saveSyncQueue([]);
        syncService.pendingCount.value = 0;

        Get.offAllNamed(Routes.login);
        SnackbarService.success('Your account and all associated data have been permanently deleted.');
        return true;
      } else {
        SnackbarService.error('Failed to delete account. Please try again.');
        return false;
      }
    } catch (e) {
      LoggerService.e('Delete account API error: $e', tag: 'SettingsController');
      AppErrorHandler.handle(e, fallback: 'Failed to delete account. Please try again.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
