import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileService extends ChangeNotifier {
  static const String _keyUserName = 'user_name';
  static const String _keyBusinessName = 'business_name';
  static const String _keyLastProfileCheck = 'last_profile_check';
  static const String _keyDarkMode = 'dark_mode';
  
  static UserProfileService? _instance;
  static SharedPreferences? _prefs;
  
  UserProfileService._();
  
  static Future<UserProfileService> getInstance() async {
    if (_instance == null) {
      _instance = UserProfileService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }
  
  // Guardar nombre del usuario
  Future<bool> setUserName(String name) async {
    return await _prefs!.setString(_keyUserName, name);
  }
  
  // Obtener nombre del usuario
  String? getUserName() {
    return _prefs!.getString(_keyUserName);
  }
  
  // Guardar nombre del negocio
  Future<bool> setBusinessName(String name) async {
    return await _prefs!.setString(_keyBusinessName, name);
  }
  
  // Obtener nombre del negocio
  String? getBusinessName() {
    return _prefs!.getString(_keyBusinessName);
  }
  
  // Verificar si el perfil está completo
  bool isProfileComplete() {
    final userName = getUserName();
    return userName != null && userName.isNotEmpty;
  }
  
  // Actualizar última vez que se verificó el perfil
  Future<bool> updateLastProfileCheck() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return await _prefs!.setInt(_keyLastProfileCheck, now);
  }
  
  // Obtener última verificación de perfil
  DateTime? getLastProfileCheck() {
    final timestamp = _prefs!.getInt(_keyLastProfileCheck);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
  
  // Verificar si debe mostrarse alerta (SIEMPRE si no está completo)
  bool shouldShowProfileAlert() {
    // Si el perfil no está completo, SIEMPRE mostrar alerta
    return !isProfileComplete();
  }
  
  // Limpiar perfil
  Future<bool> clearProfile() async {
    await _prefs!.remove(_keyUserName);
    await _prefs!.remove(_keyBusinessName);
    await _prefs!.remove(_keyLastProfileCheck);
    return true;
  }
  
  // Modo oscuro
  bool isDarkMode() {
    return _prefs!.getBool(_keyDarkMode) ?? false;
  }
  
  Future<bool> setDarkMode(bool value) async {
    final result = await _prefs!.setBool(_keyDarkMode, value);
    notifyListeners();
    return result;
  }
}
