import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../utils/app_error_handler.dart';
import 'logger_service.dart';

class GoogleAuthResult {
  final String? serverAuthCode;
  final String? idToken;
  final String? accessToken;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  GoogleAuthResult({
    this.serverAuthCode,
    this.idToken,
    this.accessToken,
    this.email,
    this.displayName,
    this.photoUrl,
  });
}

class AppleAuthResult {
  final String authorizationCode;
  final String? identityToken;
  final String userIdentifier;
  final String? givenName;
  final String? familyName;
  final String? email;

  AppleAuthResult({
    required this.authorizationCode,
    this.identityToken,
    required this.userIdentifier,
    this.givenName,
    this.familyName,
    this.email,
  });
}

class SocialAuthService {
  SocialAuthService._();

  static GoogleSignIn? _googleSignInInstance;

  static GoogleSignIn get _googleSignIn {
    if (_googleSignInInstance != null) return _googleSignInInstance!;

    String? serverClientId;
    String? clientId;
    try {
      if (dotenv.isInitialized) {
        serverClientId = dotenv.maybeGet('GOOGLE_SERVER_CLIENT_ID');
        clientId = Platform.isIOS ? dotenv.maybeGet('GOOGLE_IOS_CLIENT_ID') : null;
      }
    } catch (_) {}

    _googleSignInInstance = GoogleSignIn(
      serverClientId: serverClientId?.isNotEmpty == true ? serverClientId : null,
      clientId: clientId?.isNotEmpty == true ? clientId : null,
      scopes: const ['email', 'profile'],
    );
    return _googleSignInInstance!;
  }

  /// Triggers Google Sign In and returns the authorization code and tokens
  static Future<GoogleAuthResult?> signInWithGoogle() async {
    try {
      // Sign out first to ensure account picker appears if previously signed in
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final account = await _googleSignIn.signIn();
      if (account == null) {
        LoggerService.i('Google Sign-In cancelled by user', tag: 'SocialAuth');
        return null;
      }

      final auth = await account.authentication;
      final serverAuthCode = account.serverAuthCode;

      LoggerService.i(
        'Google Sign-In successful for ${account.email}, serverAuthCode: ${serverAuthCode != null ? "obtained" : "not present"}',
        tag: 'SocialAuth',
      );

      return GoogleAuthResult(
        serverAuthCode: serverAuthCode,
        idToken: auth.idToken,
        accessToken: auth.accessToken,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
      );
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled' ||
          e.code == '12501' ||
          e.message?.toLowerCase().contains('cancel') == true) {
        LoggerService.i('Google Sign-In cancelled by user (PlatformException)', tag: 'SocialAuth');
        return null;
      }
      LoggerService.e('Google Sign-In platform error: $e', error: e, tag: 'SocialAuth');
      rethrow;
    } catch (e, stack) {
      if (AppErrorHandler.isUserCancelled(e)) {
        LoggerService.i('Google Sign-In cancelled by user', tag: 'SocialAuth');
        return null;
      }
      LoggerService.e('Error during Google Sign-In: $e', error: e, stackTrace: stack, tag: 'SocialAuth');
      rethrow;
    }
  }

  /// Checks if Apple Sign-In is supported on the current device
  static Future<bool> isAppleSignInAvailable() async {
    try {
      if (!Platform.isIOS && !Platform.isMacOS) return false;
      return await SignInWithApple.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Triggers Apple Sign In and returns authorization code & identity token
  static Future<AppleAuthResult?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      LoggerService.i('Apple Sign-In successful for user ${credential.userIdentifier}', tag: 'SocialAuth');

      return AppleAuthResult(
        authorizationCode: credential.authorizationCode,
        identityToken: credential.identityToken,
        userIdentifier: credential.userIdentifier ?? '',
        givenName: credential.givenName,
        familyName: credential.familyName,
        email: credential.email,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        LoggerService.i('Apple Sign-In cancelled by user', tag: 'SocialAuth');
        return null;
      }
      LoggerService.e('Apple Sign-In authorization error: ${e.code} - ${e.message}', error: e, tag: 'SocialAuth');
      rethrow;
    } on PlatformException catch (e) {
      if (e.code == '1001' || e.message?.toLowerCase().contains('cancel') == true) {
        LoggerService.i('Apple Sign-In cancelled by user (PlatformException)', tag: 'SocialAuth');
        return null;
      }
      LoggerService.e('Apple Sign-In platform error: $e', error: e, tag: 'SocialAuth');
      rethrow;
    } catch (e, stack) {
      if (AppErrorHandler.isUserCancelled(e)) {
        LoggerService.i('Apple Sign-In cancelled by user', tag: 'SocialAuth');
        return null;
      }
      LoggerService.e('Error during Apple Sign-In: $e', error: e, stackTrace: stack, tag: 'SocialAuth');
      rethrow;
    }
  }
}
