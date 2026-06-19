import '../../models/auth_exception.dart';
import '../../models/zones_models.dart';

class _StoredAccount {
  const _StoredAccount({
    required this.password,
    required this.profile,
  });

  final String password;
  final UserModel profile;
}

/// Simulated auth store — replace with REST POST /register & POST /login later.
class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  final Map<String, _StoredAccount> _accounts = {
    'ahmed@zones.com': _StoredAccount(
      password: '123456',
      profile: UserModel(
        name: 'أحمد محمد',
        phone: '+218 91 234 5678',
        email: 'ahmed@zones.com',
      ),
    ),
  };

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 450));

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  bool isEmailRegistered(String email) =>
      _accounts.containsKey(_normalizeEmail(email));

  Future<UserModel> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    await _delay();

    final key = _normalizeEmail(email);
    if (_accounts.containsKey(key)) {
      throw const AuthException(
        AuthErrorType.emailAlreadyRegistered,
        'هذا البريد الإلكتروني مسجل مسبقاً',
      );
    }

    final profile = UserModel(
      name: name.trim(),
      phone: phone.trim(),
      email: key,
    );

    _accounts[key] = _StoredAccount(password: password, profile: profile);
    return profile;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    await _delay();

    final key = _normalizeEmail(email);
    final account = _accounts[key];

    if (account == null) {
      throw const AuthException(
        AuthErrorType.userNotFound,
        'عذراً، هذا الحساب غير مسجل لدينا في النظام.',
      );
    }

    if (account.password != password) {
      throw const AuthException(
        AuthErrorType.wrongPassword,
        'كلمة المرور غير صحيحة',
      );
    }

    return account.profile;
  }
}
