import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../modules/analytics/bindings/analytics_binding.dart';
import '../modules/analytics/views/analytics_view.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/auth/views/register_view.dart';
import '../modules/categories/bindings/category_binding.dart';
import '../modules/categories/views/categories_view.dart';
import '../modules/navigation/bindings/navigation_binding.dart';
import '../modules/navigation/views/main_navigation_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/transactions/bindings/transaction_binding.dart';
import '../modules/transactions/views/add_transaction_view.dart';
import '../modules/transactions/views/edit_transaction_view.dart';
import '../modules/transactions/views/transactions_view.dart';
import 'app_routes.dart';
import 'middlewares/auth_middleware.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.splash;

  static final routes = <GetPage>[
    GetPage(
      name: '/connect-hub',
      page: () => const SizedBox.shrink(),
    ),
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.register,
      page: () => const RegisterView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: Routes.dashboard,
      page: () => const MainNavigationView(),
      binding: NavigationBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.transactions,
      page: () => const TransactionsView(),
      binding: TransactionBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: Routes.addTransaction,
      page: () => const AddTransactionView(),
      binding: TransactionBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.downToUp,
    ),
    GetPage(
      name: Routes.editTransaction,
      page: () => const EditTransactionView(),
      binding: TransactionBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: Routes.categories,
      page: () => const CategoriesView(),
      binding: CategoryBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: Routes.analytics,
      page: () => const AnalyticsView(),
      binding: AnalyticsBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: Routes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeftWithFade,
    ),
  ];
}
