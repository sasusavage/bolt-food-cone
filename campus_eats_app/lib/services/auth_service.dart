import '../core/api_client.dart';
import '../models/user.dart';

class AuthService {
  Future<({String token, UserModel user})> login(
      String email, String password) async {
    final data = await ApiClient.post(
      '/api/auth/login',
      {'email': email, 'password': password},
      auth: false,
    );
    final token = data['token'] as String;
    await ApiClient.saveToken(token);
    return (token: token, user: UserModel.fromJson(data['user']));
  }

  Future<({String token, UserModel user})> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final data = await ApiClient.post(
      '/api/auth/register',
      {
        'name': name,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
      },
      auth: false,
    );
    final token = data['token'] as String;
    await ApiClient.saveToken(token);
    return (token: token, user: UserModel.fromJson(data['user']));
  }

  Future<UserModel> getMe() async {
    final data = await ApiClient.get('/api/auth/me') as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<void> logout() => ApiClient.clearToken();
}
