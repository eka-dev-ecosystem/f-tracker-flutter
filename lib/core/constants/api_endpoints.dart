import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl {
    try {
      if (dotenv.isInitialized) {
        final url = dotenv.maybeGet('API_BASE_URL');
        if (url != null && url.isNotEmpty) {
          return url;
        }
      }
    } catch (_) {}
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://be-ftracker.eka-dev.cloud',
    );
  }

  // Auth Routes (/auth/v1)
  static const String login = '/auth/v1/login';
  static const String register = '/auth/v1/register';
  static const String logout = '/auth/v1/logout';
  static const String refresh = '/auth/v1/refresh';
  static const String googleAuth = '/auth/v1/login-with-google';
  static const String appleAuth = '/auth/v1/login-with-apple';

  // Protected Routes (/api/v1)
  // Dashboard & Analytics
  static const String dashboard = '/api/v1/dashboard';
  static const String analytics = '/api/v1/analytics';

  // Transactions
  static const String transactions = '/api/v1/transactions';
  static const String transactionsCalendar = '/api/v1/transactions/calendar';
  static const String transactionSummary = '/api/v1/transactions/summary';
  static const String availableIncomes = '/api/v1/transactions/incomes/available';
  static String transactionDetail(String id) => '/api/v1/transactions/$id';

  // Categories
  static const String categories = '/api/v1/categories';
  static String categoryDetail(String id) => '/api/v1/categories/$id';

  // User Profile Settings
  static const String userMe = '/api/v1/user/me';
  static const String userSettings = '/api/v1/user/settings';
  static const String userTimezone = '/api/v1/user/timezone';
  static const String userPhone = '/api/v1/user/phone';
  static const String userChatbot = '/api/v1/user/chatbot';
  static const String bindGoogle = '/api/v1/user/bind-google';
  static const String bindApple = '/api/v1/user/bind-apple';
  static const String unbindApple = '/api/v1/user/unbind-apple';
  static const String deleteAccount = '/api/v1/user/account';
}
