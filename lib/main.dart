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
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load Environment Variables
  try {
    await dotenv.load(fileName: '.env');
    LoggerService.i('.env loaded successfully', tag: 'Bootstrap');
  } catch (e) {
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

  // Check if app was cold-launched via deep link
  final initialDeepLink = await HubDeepLinkService.checkInitialUri();
  final isDeepLinkLaunch = initialDeepLink != null;

  final hubDeepLinkService = await HubDeepLinkService().init();
  Get.put<HubDeepLinkService>(hubDeepLinkService, permanent: true);

  // If launched via deep link, DO NOT TRIGGER SPLASH SCREEN!
  final String startRoute = isDeepLinkLaunch
      ? (storageService.isLoggedIn ? Routes.dashboard : Routes.login)
      : AppPages.initial;

  LoggerService.i(
    'F-Tracker Core initialized (initialRoute: $startRoute, isDeepLink: $isDeepLinkLaunch)',
    tag: 'Bootstrap',
  );

  // 3. Run Application
  runApp(FTrackerApp(initialRoute: startRoute));
}

class FTrackerApp extends StatelessWidget {
  final String initialRoute;
  const FTrackerApp({super.key, this.initialRoute = AppPages.initial});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      defaultTransition: Transition.cupertino,
    );
  }
}
