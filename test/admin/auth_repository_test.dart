import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scarborough_tortoise_watch/features/admin/data/auth_repository.dart';

void main() {
  test('redirect result is consumed once and exposes auth failures', () async {
    var reads = 0;
    final repository = FirebaseAuthRepository(
      supportsRedirect: true,
      redirectResultLoader: () async {
        reads++;
        throw FirebaseAuthException(code: 'unauthorized-domain');
      },
    );

    await repository.processRedirectResult();
    await repository.processRedirectResult();

    expect(reads, 1);
    expect(repository.redirectError, contains('not authorised'));
  });

  test('anonymous Google redirect links the same user without sign-in',
      () async {
    final anonymous = _AnonymousUser();
    final client = _FakeGoogleRedirectClient(anonymous);
    final repository = FirebaseAuthRepository(
      redirectClient: client,
      supportsRedirect: true,
    );

    await repository.signInWithGoogle();

    expect(client.linkedUser, same(anonymous));
    expect(client.signInCalls, 0);
  });

  test('signed-in Google redirect uses sign-in without linking', () async {
    final client = _FakeGoogleRedirectClient(_SignedInUser());
    final repository = FirebaseAuthRepository(
      redirectClient: client,
      supportsRedirect: true,
    );

    await repository.signInWithGoogle();

    expect(client.linkedUser, isNull);
    expect(client.signInCalls, 1);
  });
}

class _FakeGoogleRedirectClient implements GoogleRedirectClient {
  _FakeGoogleRedirectClient(this.currentUser);

  @override
  final User? currentUser;
  User? linkedUser;
  int signInCalls = 0;

  @override
  Future<void> linkWithRedirect(User user) async {
    linkedUser = user;
  }

  @override
  Future<void> signInWithRedirect() async {
    signInCalls++;
  }
}

class _AnonymousUser implements User {
  @override
  bool get isAnonymous => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SignedInUser implements User {
  @override
  bool get isAnonymous => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
