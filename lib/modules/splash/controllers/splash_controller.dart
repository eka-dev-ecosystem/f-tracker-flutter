import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../core/services/hub_deep_link_service.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../routes/app_routes.dart';

class SplashController extends GetxController {
  final StorageService storageService;

  SplashController({required this.storageService});

  final isExiting = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    const maxWaitMs = 1200;
    var elapsedMs = 0;

    // Check for deep link or wait for entrance animation
    while (elapsedMs < maxWaitMs) {
      if (HubDeepLinkService.pendingDeepLinkUri != null) {
        LoggerService.i('Deep link detected during splash ($elapsedMs ms); accelerating transition', tag: 'Splash');
        break;
      }
      await Future.delayed(const Duration(milliseconds: 50));
      elapsedMs += 50;
    }

    final hasDeepLink = HubDeepLinkService.pendingDeepLinkUri != null;
    if (!hasDeepLink) {
      isExiting.value = true;
      AppHaptics.light();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    final targetRoute = storageService.isLoggedIn ? Routes.dashboard : Routes.login;
    
    // Do not await Get.offAllNamed because it only completes when targetRoute is popped from navigator!
    Get.offAllNamed(targetRoute);

    // Notify HubDeepLinkService on next frame when destination page is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HubDeepLinkService.instance.onNavigationReady();
    });
  }
}
