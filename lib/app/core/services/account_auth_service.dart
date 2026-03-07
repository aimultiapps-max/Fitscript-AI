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
    await _firebaseAuth.signInAnonymously();
  }

  Future<DeleteAccountResult> deleteAccountAndContinueAnonymous() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return const DeleteAccountResult(status: DeleteAccountStatus.failed);
    }

    try {
      await user.delete();
      await _firebaseAuth.signInAnonymously();
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
        await _firebaseAuth.signInAnonymously();
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
    final bytes = input.codeUnits;
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
