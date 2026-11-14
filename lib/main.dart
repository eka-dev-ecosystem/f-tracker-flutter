import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'core/constants/app_constants.dart';
import 'core/network/api_client.dart';
import 'core/services/crash_reporter_service.dart';
import 'core/services/hub_deep_link_service.dart';
import 'core/services/logger_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load Environment Variables
  try {
    await dotenv.load(fileName: '.env', isOptional: true);
    if (!dotenv.isInitialized) {
      dotenv.loadFromString(envString: '');
    }
    LoggerService.i('.env loaded successfully (isInitialized=${dotenv.isInitialized})', tag: 'Bootstrap');
  } catch (e) {
    try {
      dotenv.loadFromString(envString: '');
    } catch (_) {}
    LoggerService.w('.env could not be loaded, using defaults: $e', tag: 'Bootstrap');
  }

  // 2. Initialize Crash Reporter & Offline Observability Service (Grafana Loki)
  try {
    await CrashReporterService.instance.initialize();
  } catch (e) {
    LoggerService.w('CrashReporterService initialization warning: $e', tag: 'Bootstrap');
  }

  // 3. Global Flutter UI Framework Error Handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    CrashReporterService.instance.recordFlutterFatalError(details);
  };

  // 4. Global Asynchronous Unhandled Error Handler
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    CrashReporterService.instance.recordError(
      error,
      stack,
      fatal: true,
      reason: 'PlatformDispatcher Unhandled Async Error',
    );
    return true;
  };

  // 2. Initialize Singletons / Core Services
  final storageService = await StorageService().init();
  Get.put<StorageService>(storageService, permanent: true);

  final apiClient = ApiClient(storageService: storageService);
  Get.put<ApiClient>(apiClient, permanent: true);

  final syncService = await SyncService(
    storageService: storageService,
    apiClient: apiClient,
  ).init();
  Get.put<SyncService>(syncService, permanent: true);

  final hubDeepLinkService = await HubDeepLinkService().init();
  Get.put<HubDeepLinkService>(hubDeepLinkService, permanent: true);

  LoggerService.i('F-Tracker Core & Sync Services initialized', tag: 'Bootstrap');

  // 3. Run Application
  runApp(const FTrackerApp());
}

class FTrackerApp extends StatelessWidget {
  const FTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => const SizedBox.shrink(),
      ),
      defaultTransition: Transition.cupertino,
    );
  }
}
