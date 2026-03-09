import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

enum LinkAccountStatus { linked, signedInExisting, cancelled }

class LinkAccountResult {
  const LinkAccountResult({required this.status, required this.providerName});

  final LinkAccountStatus status;
  final String providerName;
}

enum DeleteAccountStatus { deleted, requiresRecentLogin, cancelled, failed }

class DeleteAccountResult {
  const DeleteAccountResult({required this.status, this.errorCode});

  final DeleteAccountStatus status;
  final String? errorCode;
}

class AccountAuthService {
  AccountAuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  Future<LinkAccountResult> connectWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return const LinkAccountResult(
        status: LinkAccountStatus.cancelled,
        providerName: 'Google',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _linkOrSignIn(credential, providerName: 'Google');
  }

  Future<LinkAccountResult> connectWithApple() async {
    try {
      final provider = _appleProvider();
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser != null && currentUser.isAnonymous) {
        await currentUser.linkWithProvider(provider);
        return const LinkAccountResult(
          status: LinkAccountStatus.linked,
          providerName: 'Apple',
        );
      }

      await _firebaseAuth.signInWithProvider(provider);
      return const LinkAccountResult(
        status: LinkAccountStatus.signedInExisting,
        providerName: 'Apple',
      );
    } on FirebaseAuthException catch (error) {
      if (_isUserCancelledAppleError(error.code)) {
        return const LinkAccountResult(
          status: LinkAccountStatus.cancelled,
          providerName: 'Apple',
        );
      }

      if (error.code == 'credential-already-in-use' ||
          error.code == 'provider-already-linked') {
        await _firebaseAuth.signInWithProvider(_appleProvider());
        return const LinkAccountResult(
          status: LinkAccountStatus.signedInExisting,
          providerName: 'Apple',
        );
      }

      if (_shouldFallbackToPluginAppleFlow(error.code)) {
        return _connectWithAppleUsingPlugin();
      }

      rethrow;
    }
  }

  Future<LinkAccountResult> _connectWithAppleUsingPlugin() async {
    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw FirebaseAuthException(
          code: 'apple_not_available',
          message:
              'Sign in with Apple is not available on this device/account.',
        );
      }

      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final identityToken = appleCredential.identityToken;
      if (identityToken == null || identityToken.trim().isEmpty) {
        throw FirebaseAuthException(
          code: 'apple_missing_identity_token',
          message:
              'Apple did not return a valid identity token. Please verify Apple Sign In setup.',
        );
      }

      final oauthCredential = OAuthProvider(
        'apple.com',
      ).credential(idToken: identityToken, rawNonce: rawNonce);

      return _linkOrSignIn(oauthCredential, providerName: 'Apple');
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return const LinkAccountResult(
          status: LinkAccountStatus.cancelled,
          providerName: 'Apple',
        );
      }

      final mappedCode = switch (error.code) {
        AuthorizationErrorCode.invalidResponse => 'apple_invalid_response',
        AuthorizationErrorCode.notHandled => 'apple_not_handled',
        AuthorizationErrorCode.notInteractive => 'apple_not_interactive',
        AuthorizationErrorCode.failed => 'apple_failed',
        AuthorizationErrorCode.unknown => 'apple_unknown',
        AuthorizationErrorCode.canceled => 'apple_cancelled',
        _ => 'apple_unknown',
      };

      throw FirebaseAuthException(code: mappedCode, message: error.message);
    }
  }

  Future<void> signOutToAnonymous() async {
    await _firebaseAuth.signOut();
  }

  Future<DeleteAccountResult> deleteAccountAndContinueAnonymous() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return const DeleteAccountResult(status: DeleteAccountStatus.failed);
    }

    try {
      await user.delete();
      return const DeleteAccountResult(status: DeleteAccountStatus.deleted);
    } on FirebaseAuthException catch (error) {
      if (error.code != 'requires-recent-login') {
        return DeleteAccountResult(
          status: DeleteAccountStatus.failed,
          errorCode: error.code,
        );
      }

      bool? reauthed;
      try {
        reauthed = await _tryReauthenticateForDelete(user);
      } on FirebaseAuthException catch (reauthError) {
        if (reauthError.code == 'requires-recent-login') {
          return const DeleteAccountResult(
            status: DeleteAccountStatus.requiresRecentLogin,
          );
        }
        return DeleteAccountResult(
          status: DeleteAccountStatus.failed,
          errorCode: reauthError.code,
        );
      }

      if (reauthed == null) {
        return const DeleteAccountResult(status: DeleteAccountStatus.cancelled);
      }
      if (!reauthed) {
        return const DeleteAccountResult(
          status: DeleteAccountStatus.requiresRecentLogin,
        );
      }

      try {
        await user.delete();
        return const DeleteAccountResult(status: DeleteAccountStatus.deleted);
      } on FirebaseAuthException catch (retryError) {
        return DeleteAccountResult(
          status: DeleteAccountStatus.failed,
          errorCode: retryError.code,
        );
      }
    } catch (_) {
      return const DeleteAccountResult(status: DeleteAccountStatus.failed);
    }
  }

  Future<LinkAccountResult> _linkOrSignIn(
    AuthCredential credential, {
    required String providerName,
  }) async {
    final currentUser = _firebaseAuth.currentUser;

    if (currentUser == null) {
      await _firebaseAuth.signInWithCredential(credential);
      return LinkAccountResult(
        status: LinkAccountStatus.signedInExisting,
        providerName: providerName,
      );
    }

    try {
      if (currentUser.isAnonymous) {
        await currentUser.linkWithCredential(credential);
        return LinkAccountResult(
          status: LinkAccountStatus.linked,
          providerName: providerName,
        );
      }

      await _firebaseAuth.signInWithCredential(credential);
      return LinkAccountResult(
        status: LinkAccountStatus.signedInExisting,
        providerName: providerName,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code == 'credential-already-in-use' ||
          error.code == 'provider-already-linked') {
        await _firebaseAuth.signInWithCredential(credential);
        return LinkAccountResult(
          status: LinkAccountStatus.signedInExisting,
          providerName: providerName,
        );
      }
      rethrow;
    }
  }

  Future<bool?> _tryReauthenticateForDelete(User user) async {
    final providerIds = user.providerData.map((p) => p.providerId).toSet();

    if (providerIds.contains('google.com')) {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    }

    if (providerIds.contains('apple.com')) {
      try {
        await user.reauthenticateWithProvider(_appleProvider());
        return true;
      } on FirebaseAuthException catch (error) {
        if (_isUserCancelledAppleError(error.code)) {
          return null;
        }

        if (!_shouldFallbackToPluginAppleFlow(error.code)) {
          rethrow;
        }
      }

      try {
        final rawNonce = _generateNonce();
        final nonce = _sha256ofString(rawNonce);
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [AppleIDAuthorizationScopes.email],
          nonce: nonce,
        );
        final identityToken = appleCredential.identityToken;
        if (identityToken == null || identityToken.trim().isEmpty) {
          throw FirebaseAuthException(
            code: 'apple_missing_identity_token',
            message:
                'Apple did not return a valid identity token. Please verify Apple Sign In setup.',
          );
        }
        final credential = OAuthProvider(
          'apple.com',
        ).credential(idToken: identityToken, rawNonce: rawNonce);
        await user.reauthenticateWithCredential(credential);
        return true;
      } on SignInWithAppleAuthorizationException catch (error) {
        if (error.code == AuthorizationErrorCode.canceled) {
          return null;
        }
        final mappedCode = switch (error.code) {
          AuthorizationErrorCode.invalidResponse => 'apple_invalid_response',
          AuthorizationErrorCode.notHandled => 'apple_not_handled',
          AuthorizationErrorCode.notInteractive => 'apple_not_interactive',
          AuthorizationErrorCode.failed => 'apple_failed',
          AuthorizationErrorCode.unknown => 'apple_unknown',
          AuthorizationErrorCode.canceled => 'apple_cancelled',
          _ => 'apple_unknown',
        };
        throw FirebaseAuthException(code: mappedCode, message: error.message);
      }
    }

    return false;
  }

  OAuthProvider _appleProvider() {
    final provider = OAuthProvider('apple.com');
    provider.addScope('email');
    provider.addScope('name');
    return provider;
  }

  bool _isUserCancelledAppleError(String code) {
    return code == 'canceled' ||
        code == 'web-context-cancelled' ||
        code == 'web-context-canceled';
  }

  bool _shouldFallbackToPluginAppleFlow(String code) {
    return code == 'invalid-credential' ||
        code == 'missing-or-invalid-nonce' ||
        code == 'malformed-or-expired-credential';
  }

  String _generateNonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
