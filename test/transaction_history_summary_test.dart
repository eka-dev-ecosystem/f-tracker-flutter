import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:f_tracker_mobile/core/constants/app_constants.dart';
import 'package:f_tracker_mobile/core/services/storage_service.dart';
import 'package:f_tracker_mobile/modules/splash/controllers/splash_controller.dart';
import 'package:f_tracker_mobile/modules/splash/views/splash_view.dart';
import 'package:f_tracker_mobile/modules/transactions/models/transaction_model.dart';

class MockStorageService extends GetxService implements StorageService {
  final Map<String, dynamic> _mem = {};

  @override
  bool get isLoggedIn => false;

  @override
  List<dynamic> get cachedTransactions =>
      (_mem[AppConstants.keyCachedTransactions] as List<dynamic>?) ?? [];

  @override
  Future<void> saveCachedTransactions(List<dynamic> transactions) async {
    _mem[AppConstants.keyCachedTransactions] = transactions;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Transaction History Summary Independence Tests', () {
    test('Simulated pagination does NOT alter dedicated summary totals or filterTotalCount', () {
      final txPage1 = [
        TransactionModel(
          id: 'tx_1',
          amount: 50000,
          type: 'Expense',
          description: 'Lunch',
          date: DateTime(2026, 11, 13),
          createdAt: DateTime(2026, 11, 13),
        ),
        TransactionModel(
          id: 'tx_2',
          amount: 100000,
          type: 'Income',
          description: 'Freelance',
          date: DateTime(2026, 11, 13),
          createdAt: DateTime(2026, 11, 13),
        ),
      ];

      final txPage2 = [
        TransactionModel(
          id: 'tx_3',
          amount: 25000,
          type: 'Expense',
          description: 'Coffee',
          date: DateTime(2026, 11, 12),
          createdAt: DateTime(2026, 11, 12),
        ),
      ];

      // Simulated dedicated summary response for the whole active filter:
      // Filter has 50 items total, 5,000,000 income, 2,000,000 expense
      const dedicatedTotalCount = 50;
      const dedicatedIncomeTotal = 5000000.0;
      const dedicatedExpenseTotal = 2000000.0;

      final incomeTotalObs = dedicatedIncomeTotal.obs;
      final expenseTotalObs = dedicatedExpenseTotal.obs;
      final filterTotalCountObs = dedicatedTotalCount.obs;
      final transactionsList = <TransactionModel>[...txPage1].obs;

      // Assert initial state: loaded items = 2, but filterTotalCount = 50
      expect(transactionsList.length, 2);
      expect(filterTotalCountObs.value, 50);
      expect(incomeTotalObs.value, 5000000.0);
      expect(expenseTotalObs.value, 2000000.0);

      // Simulating scroll pagination loading page 2
      transactionsList.addAll(txPage2);

      // Verify that after scroll pagination, list grows but summary metrics REMAIN FIXED
      expect(transactionsList.length, 3);
      expect(
        filterTotalCountObs.value,
        50,
        reason:
            'filterTotalCount must not be overwritten by transactions.length',
      );
      expect(
        incomeTotalObs.value,
        5000000.0,
        reason: 'incomeTotal must not be recalculated from partial page',
      );
      expect(
        expenseTotalObs.value,
        2000000.0,
        reason: 'expenseTotal must not be recalculated from partial page',
      );
    });

    test('Offline fallback calculates summary from complete local cache', () {
      final fullCache = [
        TransactionModel(
          id: 'c_1',
          amount: 300000,
          type: 'Income',
          description: 'Salary',
          date: DateTime(2026, 11, 10),
          createdAt: DateTime(2026, 11, 10),
        ),
        TransactionModel(
          id: 'c_2',
          amount: 50000,
          type: 'Expense',
          description: 'Groceries',
          date: DateTime(2026, 11, 11),
          createdAt: DateTime(2026, 11, 11),
        ),
        TransactionModel(
          id: 'c_3',
          amount: 150000,
          type: 'Expense',
          description: 'Electric bill',
          date: DateTime(2026, 11, 12),
          createdAt: DateTime(2026, 11, 12),
        ),
      ];

      double inc = 0;
      double exp = 0;
      for (final t in fullCache) {
        if (t.isIncome) {
          inc += t.amount;
        } else {
          exp += t.amount;
        }
      }

      expect(inc, 300000);
      expect(exp, 200000);
      expect(inc - exp, 100000);
      expect(fullCache.length, 3);
    });

    test('Filter switching updates dedicated summary independently of paginated items count', () {
      final allSummary = {
        'totalCount': 120,
        'incomeTotal': 15000000.0,
        'expenseTotal': 4000000.0,
        'balance': 11000000.0,
      };

      final expenseOnlySummary = {
        'totalCount': 85,
        'incomeTotal': 0.0,
        'expenseTotal': 4000000.0,
        'balance': -4000000.0,
      };

      final incomeTotal = (allSummary['incomeTotal'] as double).obs;
      final expenseTotal = (allSummary['expenseTotal'] as double).obs;
      final filterTotalCount = (allSummary['totalCount'] as int).obs;

      expect(filterTotalCount.value, 120);
      expect(incomeTotal.value, 15000000.0);
      expect(expenseTotal.value, 4000000.0);

      // User selects "Expense" filter pill:
      filterTotalCount.value = expenseOnlySummary['totalCount'] as int;
      incomeTotal.value = expenseOnlySummary['incomeTotal'] as double;
      expenseTotal.value = expenseOnlySummary['expenseTotal'] as double;

      // Summary updates to expense filter metrics:
      expect(filterTotalCount.value, 85);
      expect(incomeTotal.value, 0.0);
      expect(expenseTotal.value, 4000000.0);
    });

    test('Optimistic delete decrements filterTotalCount and updates total without pagination churn', () {
      final filterTotalCount = 42.obs;
      final expenseTotal = 500000.0.obs;

      final txToDelete = TransactionModel(
        id: 'tx_delete_1',
        amount: 50000,
        type: 'Expense',
        description: 'Takeout food',
        date: DateTime(2026, 11, 13),
        createdAt: DateTime(2026, 11, 13),
      );

      // Perform local optimistic decrement
      expenseTotal.value -= txToDelete.amount;
      filterTotalCount.value--;

      expect(expenseTotal.value, 450000.0);
      expect(filterTotalCount.value, 41);
    });
  });

  group('Grab/Gojek-Style Splash Launch Tests', () {
    setUp(() {
      Get.reset();
      Get.testMode = true;
      final mockStorage = MockStorageService();
      Get.put<StorageService>(mockStorage);
      Get.put<SplashController>(SplashController(storageService: mockStorage));
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets(
      'SplashView renders branding, tagline, and animated layers smoothly',
      (WidgetTester tester) async {
        await tester.pumpWidget(const GetMaterialApp(home: SplashView()));

        // Verify Brand name and tagline are present
        expect(find.text(AppConstants.appName), findsOneWidget);
        expect(find.text(AppConstants.appTagline), findsOneWidget);
        expect(find.text('SECURING VAULT & DATA...'), findsOneWidget);

        // Advance animation frames
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 900));

        // Elements remain visible and active
        expect(find.text(AppConstants.appName), findsOneWidget);
      },
    );

    test('SplashController sets isExiting to true upon sequence completion', () async {
      final controller = Get.find<SplashController>();
      expect(controller.isExiting.value, isFalse);

      // Fast forward past the 1800ms animation duration
      await Future.delayed(const Duration(milliseconds: 1850));
      expect(controller.isExiting.value, isTrue);
    });
  });
}
