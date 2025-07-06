import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage;
  bool _isAuthenticated = false;
  String? _currentUserId;

  AuthService(this._secureStorage) {
    _checkAuthState();
  }

  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUserId;

  Future<void> _checkAuthState() async {
    final userId = await _secureStorage.read(key: 'user_id');
    final authToken = await _secureStorage.read(key: 'auth_token');
    
    if (userId != null && authToken != null) {
      _currentUserId = userId;
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<bool> authenticate(String password) async {
    // Simulez autentificarea cu parolă
    // În implementarea reală, ar trebui să verifici parola cu hash-ul stocat
    final storedPasswordHash = await _secureStorage.read(key: 'password_hash');
    
    if (storedPasswordHash == null) {
      // Prima autentificare - setează parola
      return await _setInitialPassword(password);
    } else {
      // Verifică parola existentă
      final passwordHash = _hashPassword(password);
      if (passwordHash == storedPasswordHash) {
        _isAuthenticated = true;
        _currentUserId = 'user_default';
        await _secureStorage.write(key: 'auth_token', value: 'authenticated');
        notifyListeners();
        return true;
      }
      return false;
    }
  }

  Future<bool> _setInitialPassword(String password) async {
    final passwordHash = _hashPassword(password);
    await _secureStorage.write(key: 'password_hash', value: passwordHash);
    await _secureStorage.write(key: 'user_id', value: 'user_default');
    await _secureStorage.write(key: 'auth_token', value: 'authenticated');
    
    _isAuthenticated = true;
    _currentUserId = 'user_default';
    notifyListeners();
    return true;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode('${password}pcq_salt_2024');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: 'auth_token');
    _isAuthenticated = false;
    _currentUserId = null;
    notifyListeners();
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final storedPasswordHash = await _secureStorage.read(key: 'password_hash');
    final oldPasswordHash = _hashPassword(oldPassword);
    
    if (oldPasswordHash == storedPasswordHash) {
      final newPasswordHash = _hashPassword(newPassword);
      await _secureStorage.write(key: 'password_hash', value: newPasswordHash);
      return true;
    }
    return false;
  }

  Future<bool> hasPasswordSet() async {
    final passwordHash = await _secureStorage.read(key: 'password_hash');
    return passwordHash != null;
  }

  Future<void> reset() async {
    await _secureStorage.deleteAll();
    _isAuthenticated = false;
    _currentUserId = null;
    notifyListeners();
  }
}
