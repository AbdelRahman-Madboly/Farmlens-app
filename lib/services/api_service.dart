import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/live_data.dart';
import '../models/cycle_log.dart';
import '../models/node_status.dart';
import '../models/fusion_settings.dart';
import '../constants.dart';

class ApiService {
  final String baseUrl;
  final Duration _timeout =
      const Duration(seconds: FarmLensConstants.apiTimeoutSeconds);

  ApiService(this.baseUrl);

  Future<NodeStatus?> getStatus() async {
    try {
      final uri = Uri.parse('$baseUrl/api/status');
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode == 200) {
        return NodeStatus.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<LiveData?> getLive() async {
    try {
      final uri = Uri.parse('$baseUrl/api/live');
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode == 200) {
        return LiveData.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<CycleLog>> getLogs({int limit = 50}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/logs?limit=$limit');
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final logs = body['logs'] as List<dynamic>? ?? [];
        return logs
            .map((e) => CycleLog.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<FusionSettings?> getSettings() async {
    try {
      final uri = Uri.parse('$baseUrl/api/settings');
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode == 200) {
        return FusionSettings.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> postSettings(FusionSettings s) async {
    try {
      final uri = Uri.parse('$baseUrl/api/settings');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(s.toJson()),
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['ok'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}