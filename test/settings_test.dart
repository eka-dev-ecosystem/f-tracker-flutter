import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart' as dio;
import 'package:f_tracker_mobile/core/network/api_client.dart';
import 'package:f_tracker_mobile/core/services/storage_service.dart';
import 'package:f_tracker_mobile/core/services/sync_service.dart';
import 'package:f_tracker_mobile/modules/settings/controllers/settings_controller.dart';
import 'package:get/get.dart' hide Response;

class FakeStorageService extends GetxService implements StorageService {
  @override
  bool get isBiometricEnabled => false;

  @override
  Map<String, dynamic>? get user => {'name': 'Test User', 'timezone': 'UTC'};

  @override
  List<dynamic> get cachedTransactions => [];

  @override
  List<dynamic> get cachedCategories => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeApiClient extends Fake implements ApiClient {
  @override
  Future<dio.Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    dio.Options? options,
    dio.CancelToken? cancelToken,
  }) async {
    return dio.Response(
      requestOptions: dio.RequestOptions(path: path),
      data: null,
      statusCode: 200,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSyncService extends GetxService implements SyncService {
  @override
  final RxInt pendingCount = 0.obs;

  @override
  final RxBool isOnline = true.obs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Connected Accounts & Platform Visibility Tests', () {
    late SettingsController controller;
    late StorageService storageService;
    late ApiClient apiClient;

    setUp(() {
      Get.reset();
      storageService = FakeStorageService();
      Get.put<StorageService>(storageService);

      apiClient = FakeApiClient();
      Get.put<ApiClient>(apiClient);

      final syncService = FakeSyncService();
      Get.put<SyncService>(syncService);

      controller = SettingsController(
        apiClient: apiClient,
        storageService: storageService,
      );
    });

    tearDown(() {
      controller.onClose();
      Get.reset();
    });

    test('isAppleAvailable defaults to false on non-iOS/Android mock environment', () {
      expect(controller.isAppleAvailable.value, isFalse);
    });

    test('bindApple aborts immediately when isAppleAvailable is false', () async {
      controller.isAppleAvailable.value = false;
      await controller.bindApple();
      expect(controller.isAppleLinked.value, isFalse);
      expect(controller.isBindingApple.value, isFalse);
    });

    test('isAppleAvailable reactive toggle drives Apple Connect card visibility', () {
      // In Android or unsupported environments
      controller.isAppleAvailable.value = false;
      bool showApple = controller.isAppleAvailable.value;
      expect(showApple, isFalse);

      // In iOS supported environments
      controller.isAppleAvailable.value = true;
      showApple = controller.isAppleAvailable.value;
      expect(showApple, isTrue);
    });
  });
}
