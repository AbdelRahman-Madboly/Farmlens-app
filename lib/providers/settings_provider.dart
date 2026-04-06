import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fusion_settings.dart';
import '../constants.dart';

class SettingsProvider extends ChangeNotifier {
  String _deviceBaseUrl = '';
  FusionSettings _fusionSettings = FusionSettings.defaults();

  String get deviceBaseUrl => _deviceBaseUrl;
  FusionSettings get fusionSettings => _fusionSettings;
  bool get isConfigured => _deviceBaseUrl.isNotEmpty;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceBaseUrl = prefs.getString(FarmLensConstants.prefKeyBaseUrl) ?? '';
    notifyListeners();
  }

  Future<void> saveDeviceUrl(String url) async {
    _deviceBaseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(FarmLensConstants.prefKeyBaseUrl, url);
    notifyListeners();
  }

  Future<void> clearDeviceUrl() async {
    _deviceBaseUrl = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(FarmLensConstants.prefKeyBaseUrl);
    notifyListeners();
  }

  void updateFusionSettings(FusionSettings s) {
    _fusionSettings = s;
    notifyListeners();
  }
}