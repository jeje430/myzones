import 'package:flutter/foundation.dart';

import '../data/repositories/auth_repository.dart';
import '../models/auth_exception.dart';
import '../models/zones_models.dart';
import '../services/zones_api_service.dart';
import 'app_state_provider.dart';
import 'zones_data_provider.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository.instance;

  UserModel? _sessionUser;
  bool _isBusy = false;
  String? _error;

  UserModel? get sessionUser => _sessionUser;
  bool get isAuthenticated => _sessionUser != null;
  bool get isBusy => _isBusy;
  String? get error => _error;

  void _applySession(
    UserModel user, {
    required AppStateProvider appState,
    required ZonesDataProvider zonesData,
  }) {
    _sessionUser = user;
    ZonesApiService.instance.setCurrentUser(user);
    zonesData.applyUserProfile(user);
    appState.updateProfile(name: user.name, phone: user.phone);
  }

  Future<UserModel> registerAccount({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    _isBusy = true;
    _error = null;
    notifyListeners();

    try {
      return await _repository.signUp(
        name: name,
        phone: phone,
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<UserModel> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
    required AppStateProvider appState,
    required ZonesDataProvider zonesData,
  }) async {
    final user = await registerAccount(
      name: name,
      phone: phone,
      email: email,
      password: password,
    );
    _applySession(user, appState: appState, zonesData: zonesData);
    return user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
    required AppStateProvider appState,
    required ZonesDataProvider zonesData,
  }) async {
    _isBusy = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _repository.login(
        email: email,
        password: password,
      );
      _applySession(user, appState: appState, zonesData: zonesData);
      return user;
    } on AuthException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void signOut() {
    _sessionUser = null;
    _error = null;
    notifyListeners();
  }
}
