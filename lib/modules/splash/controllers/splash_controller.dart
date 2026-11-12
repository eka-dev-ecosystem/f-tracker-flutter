import 'package:get/get.dart';
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
    // 1800ms duration allows the Grab/Gojek-style spring entrance and breathing aura to play fluidly
    await Future.delayed(const Duration(milliseconds: 1800));
    isExiting.value = true;
    AppHaptics.light();
    await Future.delayed(const Duration(milliseconds: 320));
    if (storageService.isLoggedIn) {
      Get.offAllNamed(Routes.dashboard);
    } else {
      Get.offAllNamed(Routes.login);
    }
  }
}
