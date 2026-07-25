import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  static const String baseUrl = 'https://bom-dia-zap-production.up.railway.app';
  static const _tokenKey = 'auth_token';

  String? _token;
  User? _currentUser;

  bool get isLoggedIn => _token != null;
  User? get currentUser => _currentUser;

  Map<String, String> get authHeaders =>
      _token != null ? {'Authorization': 'Bearer $_token'} : {};

  /// Restaura a sessão salva (se houver) — chamado uma vez no início do app.
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);

    if (_token == null) return;

    try {
      await fetchMe();
    } catch (_) {
      await logout();
    }
  }

  Future<User> register(String email, String password) {
    return _authenticate('/auth/register', email, password);
  }

  Future<User> login(String email, String password) {
    return _authenticate('/auth/login', email, password);
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<User> fetchMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: authHeaders,
    );

    if (response.statusCode != 200) {
      throw AuthException('Sessão expirada, entre novamente.');
    }

    _currentUser = User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    return _currentUser!;
  }

  Future<User> _authenticate(String path, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AuthException(body['message']?.toString() ?? 'Não foi possível autenticar.');
    }

    await _saveToken(body['accessToken'] as String);
    _currentUser = User.fromJson(body['user'] as Map<String, dynamic>);
    return _currentUser!;
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
}

final authService = AuthService();
