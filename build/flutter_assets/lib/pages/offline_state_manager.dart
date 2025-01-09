<<<<<<< HEAD
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class OfflineStateManager {
  static const String _keyIdForm = 'idForm';
  static const String _keyIdUser = 'idUser';
  static const String _keyIsConnected = 'isConnected';
  static const String _keyUserName = 'userName';

  static final StreamController<bool> _connectivityStreamController =
      StreamController<bool>.broadcast();

  static Stream<bool> get connectivityStream =>
      _connectivityStreamController.stream;

  static StreamSubscription<List<ConnectivityResult>>?
      _connectivitySubscription;

  static void startMonitoringConnectivity() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      bool isConnected =
          results.isNotEmpty && results.first != ConnectivityResult.none;
      _connectivityStreamController.add(isConnected);
      _saveConnectivityState(isConnected);
    });

    // Check initial connectivity state
    checkConnectivity().then((isConnected) {
      _connectivityStreamController.add(isConnected);
    });
  }

  static void stopMonitoringConnectivity() {
    _connectivitySubscription?.cancel();
    _connectivityStreamController.close();
  }

  static Future<void> _saveConnectivityState(bool isConnected) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsConnected, isConnected);
  }

  // Save idForm (integer)
  static Future<bool> saveIdForm(int idForm) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_keyIdForm, idForm);
  }

  // Get idForm
  static Future<int?> getIdForm() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyIdForm);
  }

  // Save idUser (string)
  static Future<bool> saveIdUser(String idUser) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_keyIdUser, idUser);
  }

  // Get idUser
  static Future<String?> getIdUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyIdUser);
  }

  // New method to save username
  static Future<bool> saveUserName(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_keyUserName, userName);
  }

  // New method to get username
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  // Check connectivity
  static Future<bool> checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    bool isConnected = connectivityResult != ConnectivityResult.none;

    // Save connectivity state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsConnected, isConnected);

    return isConnected;
  }

  // Get saved connectivity state
  static Future<bool> getIsConnected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsConnected) ?? false;
  }

  // Clear all stored data
  static Future<bool> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.clear();
=======
import 'dart:async';

class OfflineStateManager {
  static final OfflineStateManager _instance = OfflineStateManager._internal();
  factory OfflineStateManager() => _instance;
  OfflineStateManager._internal();

  // Stream controllers
  final _userIdController = StreamController<String>.broadcast();
  
  // Current values
  String? _currentUserId;

  // Getters
  Stream<String> get userIdStream => _userIdController.stream;
  String? get currentUserId => _currentUserId;

  // Setters
  void setUserId(String userId) {
    _currentUserId = userId;
    _userIdController.add(userId);
  }

  // Cleanup
  void dispose() {
    _userIdController.close();
>>>>>>> 0f5210f5847071cc155d66aa2117f7a0eba6918b
  }
}
