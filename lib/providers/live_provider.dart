import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/live_data.dart';
import '../models/cycle_log.dart';
import '../services/api_service.dart';
import '../constants.dart';

class LiveProvider extends ChangeNotifier {
  LiveData _latest = LiveData.empty();
  final List<CycleLog> _alerts = [];
  int _unreadAlertCount = 0;
  String _lastCycleId = '';
  Timer? _timer;
  int _consecutiveErrors = 0;
  bool _isOffline = false;

  LiveData get latest => _latest;
  List<CycleLog> get alerts => List.unmodifiable(_alerts);
  int get unreadAlertCount => _unreadAlertCount;
  bool get isOffline => _isOffline;

  void markAlertsRead() {
    _unreadAlertCount = 0;
    notifyListeners();
  }

  void startPolling(ApiService api) {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: FarmLensConstants.pollIntervalSeconds),
      (_) => _poll(api),
    );
    _poll(api);
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll(ApiService api) async {
    final data = await api.getLive();
    if (data == null) {
      _consecutiveErrors++;
      if (_consecutiveErrors >= 3) {
        _isOffline = true;
        notifyListeners();
      }
    } else {
      _consecutiveErrors = 0;
      _isOffline = false;
      _onNewData(data);
    }
  }

  void _onNewData(LiveData d) {
    _latest = d;
    if (d.cycleId.isNotEmpty && d.cycleId != _lastCycleId) {
      _lastCycleId = d.cycleId;
      if (d.alert) {
        final log = CycleLog.fromLiveData(d);
        _alerts.insert(0, log);
        _unreadAlertCount++;
        if (_alerts.length > 200) _alerts.removeLast();
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}