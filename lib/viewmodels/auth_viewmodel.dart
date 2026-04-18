import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../core/api_client.dart';

enum AuthState { idle, loading, authenticated, error }

class AuthViewModel extends ChangeNotifier {
  final _service = AuthService();

  AuthState state = AuthState.idle;
  UserModel? currentUser;
  String? errorMessage;

  bool get isAuthenticated => currentUser != null;
  bool get isAdmin => currentUser?.isAdmin ?? false;

  Future<void> login(String email, String password) async {
    state = AuthState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _service.login(email, password);
      currentUser = result.user;
      state = AuthState.authenticated;
    } on ApiException catch (e) {
      errorMessage = e.message;
      state = AuthState.error;
    } catch (e) {
      errorMessage = e.toString();
      state = AuthState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = AuthState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _service.register(
          name: name, email: email, password: password, phone: phone);
      currentUser = result.user;
      state = AuthState.authenticated;
    } on ApiException catch (e) {
      errorMessage = e.message;
      state = AuthState.error;
    } catch (e) {
      errorMessage = e.toString();
      state = AuthState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _service.logout();
    currentUser = null;
    state = AuthState.idle;
    notifyListeners();
  }

  Future<void> tryRestoreSession() async {
    try {
      currentUser = await _service.getMe();
      state = AuthState.authenticated;
    } catch (_) {
      state = AuthState.idle;
    }
    notifyListeners();
  }
}
