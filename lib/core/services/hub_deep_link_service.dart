import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/logger_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../../modules/auth/models/user_model.dart';
import '../../routes/app_routes.dart';

class HubDeepLinkService extends GetxService {
  static HubDeepLinkService get instance => Get.find<HubDeepLinkService>();

  static Uri? pendingDeepLinkUri;

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  Future<HubDeepLinkService> init() async {
    _appLinks = AppLinks();
    _initDeepLinks();
    return this;
  }

  void _initDeepLinks() {
    // 1. Initial link
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        LoggerService.i('Initial deep link detected: $uri', tag: 'HubDeepLink');
        handleIncomingUri(uri);
      }
    }).catchError((err) {
      LoggerService.w('Failed to get initial deep link: $err', tag: 'HubDeepLink');
    });

    // 2. Listen to subsequent stream of deep links while running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        LoggerService.i('Incoming deep link stream: $uri', tag: 'HubDeepLink');
        handleIncomingUri(uri);
      },
      onError: (err) {
        LoggerService.w('Deep link stream error: $err', tag: 'HubDeepLink');
      },
    );
  }

  void handleIncomingUri(Uri uri) {
    if (uri.scheme != 'ftracker') return;

    final hostOrPath = uri.host.isNotEmpty ? uri.host : uri.path.replaceAll('/', '');
    if (hostOrPath == 'connect-hub') {
      final sessionCode = uri.queryParameters['session_code'];
      final callbackUrl = uri.queryParameters['callback_url'] ?? 'ekahub://link-callback';

      if (sessionCode == null || sessionCode.isEmpty) {
        LoggerService.w('connect-hub deep link missing session_code: $uri', tag: 'HubDeepLink');
        return;
      }

      pendingDeepLinkUri = uri;

      // If app is currently on splash screen, wait until SplashController navigates
      if (Get.currentRoute == Routes.splash || Get.currentRoute.isEmpty) {
        LoggerService.i('Current route is ${Get.currentRoute}; deferring confirmation sheet until target page ready', tag: 'HubDeepLink');
        return;
      }

      _presentConfirmationSheet(sessionCode, callbackUrl);
    }
  }

  void onNavigationReady() {
    final uri = pendingDeepLinkUri;
    if (uri != null) {
      pendingDeepLinkUri = null;
      final sessionCode = uri.queryParameters['session_code'];
      final callbackUrl = uri.queryParameters['callback_url'] ?? 'ekahub://link-callback';
      if (sessionCode != null && sessionCode.isNotEmpty) {
        LoggerService.i('Triggering deferred deep link sheet on target route: ${Get.currentRoute}', tag: 'HubDeepLink');
        _presentConfirmationSheet(sessionCode, callbackUrl);
      }
    }
  }

  void _presentConfirmationSheet(String sessionCode, String callbackUrl) {
    void tryShow() {
      if (Get.context != null && Get.isOverlaysClosed) {
        showHubLinkConfirmationSheet(
          sessionCode: sessionCode,
          callbackUrl: callbackUrl,
        );
      } else if (Get.context != null) {
        Future.delayed(const Duration(milliseconds: 150), () {
          showHubLinkConfirmationSheet(
            sessionCode: sessionCode,
            callbackUrl: callbackUrl,
          );
        });
      } else {
        Future.delayed(const Duration(milliseconds: 100), tryShow);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      tryShow();
    });
  }

  void showHubLinkConfirmationSheet({
    required String sessionCode,
    required String callbackUrl,
  }) {
    final storage = Get.find<StorageService>();

    if (!storage.isLoggedIn || storage.user == null) {
      Get.defaultDialog(
        title: 'Masuk Terlebih Dahulu',
        titleStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: AppColors.surface,
        middleText:
            'Anda harus masuk ke akun F-Tracker Anda sebelum dapat menghubungkannya ke Eka-Hub.',
        middleTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        textConfirm: 'Masuk Sekarang',
        textCancel: 'Batal',
        confirmTextColor: Colors.white,
        buttonColor: AppColors.primary,
        cancelTextColor: AppColors.textSecondary,
        onConfirm: () {
          Get.back();
          // Navigate to login
          Get.toNamed('/login');
        },
        onCancel: () {
          _launchCallback(callbackUrl, status: 'cancelled');
        },
      );
      return;
    }

    final user = UserModel.fromJson(storage.user!);
    final isLoading = false.obs;
    final errorMessage = ''.obs;

    Get.bottomSheet(
      Material(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Logos and connection icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(
                        Icons.swap_horiz_rounded,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                        size: 28,
                      ),
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  'Hubungkan ke Personal AI Hub',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Personal AI Hub meminta izin membaca ringkasan keuangan, saldo kas, dan riwayat transaksi untuk asisten AI Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // User account card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name.substring(0, 1).toUpperCase()
                              : 'F',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name.isNotEmpty ? user.name : 'Pengguna F-Tracker',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Aktif',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (errorMessage.value.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage.value,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Approve button
                ElevatedButton(
                  onPressed: isLoading.value
                      ? null
                      : () => _executeExchange(
                            sessionCode: sessionCode,
                            callbackUrl: callbackUrl,
                            user: user,
                            token: storage.accessToken ?? '',
                            isLoading: isLoading,
                            errorMessage: errorMessage,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Izinkan Akses',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 10),

                // Cancel button
                TextButton(
                  onPressed: isLoading.value
                      ? null
                      : () {
                          Get.back();
                          _launchCallback(callbackUrl, status: 'cancelled');
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Batalkan'),
                ),
              ],
            ),
          ),
        ),
      ),
      isDismissible: !isLoading.value,
      enableDrag: !isLoading.value,
      isScrollControlled: true,
    );
  }

  Future<void> _executeExchange({
    required String sessionCode,
    required String callbackUrl,
    required UserModel user,
    required String token,
    required RxBool isLoading,
    required RxString errorMessage,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final payload = {
        'session_code': sessionCode,
        'app_id': 'ftracker',
        'app_name': 'F-Tracker',
        'connected_uid': user.id,
        'connected_email': user.email,
        'api_base_url': 'https://be-ftracker.eka-dev.cloud',
        'read_only_token': token,
        'custom_url_scheme': 'ftracker://',
      };

      final response = await dio.post(
        'https://hub-api.eka-dev.cloud/api/v1/hub/link/exchange',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back(); // close sheet
        Get.snackbar(
          'Berhasil Terhubung',
          'Akun F-Tracker berhasil dihubungkan ke Personal AI Hub.',
          backgroundColor: AppColors.surface,
          colorText: AppColors.textPrimary,
          icon: const Icon(Icons.check_circle, color: AppColors.success),
          duration: const Duration(seconds: 2),
        );

        await Future.delayed(const Duration(milliseconds: 600));
        await _launchCallback(callbackUrl, status: 'success');
      } else {
        errorMessage.value = 'Gagal menghubungkan: ${response.statusMessage ?? "Status ${response.statusCode}"}';
      }
    } catch (e) {
      if (e is DioException) {
        final errData = e.response?.data;
        if (errData is Map && errData['message'] != null) {
          errorMessage.value = errData['message'].toString();
        } else {
          errorMessage.value = 'Koneksi ke Hub API gagal (${e.type.name}).';
        }
      } else {
        errorMessage.value = 'Terjadi kesalahan: $e';
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _launchCallback(String callbackUrl, {required String status}) async {
    pendingDeepLinkUri = null;
    try {
      final baseUri = Uri.parse(callbackUrl);
      final queryParams = Map<String, String>.from(baseUri.queryParameters);
      queryParams['status'] = status;
      queryParams['app_id'] = 'ftracker';

      final finalUri = baseUri.replace(queryParameters: queryParams);
      LoggerService.i('Launching link callback: $finalUri', tag: 'HubDeepLink');

      await launchUrl(
        finalUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      LoggerService.w('Failed to launch callback $callbackUrl: $e', tag: 'HubDeepLink');
    }
  }

  @override
  void onClose() {
    _linkSubscription?.cancel();
    super.onClose();
  }
}
