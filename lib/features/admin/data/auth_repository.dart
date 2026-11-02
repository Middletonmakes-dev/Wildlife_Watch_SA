import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

abstract interface class AuthRepository {
  User? get currentUser;
  Stream<User?> get authStateChanges;
  Stream<User?> get idTokenChanges;
  String? get redirectError;
  Future<void> signInWithGoogle();
  Future<void> processRedirectResult();
  Future<bool> checkAccess({bool forceRefresh = false});
  Future<void> signOut();
}

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DemoAuthRepository implements AuthRepository {
  const DemoAuthRepository();

  @override
  User? get currentUser => null;

  @override
  String? get redirectError => null;

  @override
  Stream<User?> get authStateChanges => const Stream<User?>.empty();

  @override
  Stream<User?> get idTokenChanges => const Stream<User?>.empty();

  @override
  Future<void> signInWithGoogle() async {
    throw const AuthRepositoryException(
      'Google sign-in is available only in the configured Firebase app.',
    );
  }

  @override
  Future<void> processRedirectResult() async {}

  @override
  Future<bool> checkAccess({bool forceRefresh = false}) async => false;

  @override
  Future<void> signOut() async {}
}

abstract interface class GoogleRedirectClient {
  User? get currentUser;
  Future<void> linkWithRedirect(User user);
  Future<void> signInWithRedirect();
}

class FirebaseGoogleRedirectClient implements GoogleRedirectClient {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<void> linkWithRedirect(User user) =>
      user.linkWithRedirect(GoogleAuthProvider());

  @override
  Future<void> signInWithRedirect() =>
      _auth.signInWithRedirect(GoogleAuthProvider());
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    GoogleRedirectClient? redirectClient,
    Future<void> Function()? redirectResultLoader,
    bool? supportsRedirect,
  })  : _redirectClient = redirectClient ?? FirebaseGoogleRedirectClient(),
        _redirectResultLoader = redirectResultLoader,
        _supportsRedirect = supportsRedirect ?? kIsWeb;

  FirebaseAuth get _auth => FirebaseAuth.instance;
  final GoogleRedirectClient _redirectClient;
  final Future<void> Function()? _redirectResultLoader;
  final bool _supportsRedirect;
  bool _redirectResultProcessed = false;
  String? _redirectError;

  @override
  User? get currentUser => _redirectClient.currentUser;

  @override
  String? get redirectError => _redirectError;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Stream<User?> get idTokenChanges => _auth.idTokenChanges();

  @override
  Future<void> signInWithGoogle() async {
    if (!_supportsRedirect) {
      throw const AuthRepositoryException(
        'Google sign-in is available only in the configured Firebase web app.',
      );
    }
    try {
      final current = _redirectClient.currentUser;
      if (current?.isAnonymous == true) {
        // Linking preserves the anonymous UID and therefore preserves
        // ownership of reports already submitted in this browser.
        await _redirectClient.linkWithRedirect(current!);
      } else {
        await _redirectClient.signInWithRedirect();
      }
    } on FirebaseAuthException catch (error) {
      throw AuthRepositoryException(authErrorMessage(error));
    } catch (_) {
      throw const AuthRepositoryException(
        'Google sign-in could not be completed. Please try again.',
      );
    }
  }

  @override
  Future<void> processRedirectResult() async {
    if (!_supportsRedirect || _redirectResultProcessed) return;
    _redirectResultProcessed = true;
    try {
      if (_redirectResultLoader != null) {
        await _redirectResultLoader();
      } else {
        await _auth.getRedirectResult();
      }
    } on FirebaseAuthException catch (error) {
      _redirectError = authErrorMessage(error);
    } catch (_) {
      _redirectError =
          'Google sign-in could not be completed. Please try again.';
    }
  }

  @override
  Future<bool> checkAccess({bool forceRefresh = false}) async {
    final user = currentUser;
    if (user == null) return false;
    try {
      final token = await user.getIdTokenResult(forceRefresh);
      final claims = token.claims ?? const <String, Object?>{};
      return claims['admin'] == true ||
          claims['role'] == 'admin' ||
          claims['role'] == 'analyst';
    } on FirebaseAuthException catch (error) {
      throw AuthRepositoryException(authErrorMessage(error));
    } catch (_) {
      throw const AuthRepositoryException(
        'Access could not be checked. Please try again.',
      );
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

String authErrorMessage(FirebaseAuthException error) => switch (error.code) {
      'popup-closed-by-user' ||
      'cancelled-popup-request' =>
        'Google sign-in was cancelled.',
      'popup-blocked' =>
        'Google sign-in could not be started in this browser. Please try again.',
      'auth-domain-config-required' =>
        'Google sign-in is not configured for this app domain yet.',
      'unauthorized-domain' =>
        'Google sign-in is not authorised for this app domain yet.',
      'operation-not-supported-in-this-environment' =>
        'Google sign-in is not supported in this browser environment.',
      'operation-not-allowed' =>
        'Google sign-in is not enabled for this app yet.',
      'account-exists-with-different-credential' ||
      'credential-already-in-use' =>
        'That Google account is already attached elsewhere. Open a separate browser for admin access so this reporter account stays linked to its reports.',
      'network-request-failed' =>
        'Google sign-in needs a network connection. Please try again.',
      _ => 'Google sign-in could not be completed. Please try again.',
    };
