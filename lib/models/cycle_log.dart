import 'live_data.dart';

class CycleLog {
  final String id;
  final int ts;
  final String nodeId;
  final double moisturePct;
  final double waterPct;
  final double cs;
  final double cv;
  final double ccombined;
  final bool alert;
  final String detectionClass;
  final double detectionConf;

  const CycleLog({
    required this.id,
    required this.ts,
    required this.nodeId,
    required this.moisturePct,
    required this.waterPct,
    required this.cs,
    required this.cv,
    required this.ccombined,
    required this.alert,
    required this.detectionClass,
    required this.detectionConf,
  });

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory CycleLog.fromJson(Map<String, dynamic> json) {
    return CycleLog(
      id: json['id']?.toString() ?? '',
      ts: (json['ts'] as num?)?.toInt() ?? 0,
      nodeId: json['node_id']?.toString() ?? '',
      moisturePct: _d(json['moisture_pct']),
      waterPct: _d(json['water_pct']),
      cs: _d(json['cs']),
      cv: _d(json['cv']),
      ccombined: _d(json['ccombined']),
      alert: json['alert'] == true,
      detectionClass: json['detection_class']?.toString() ?? '',
      detectionConf: _d(json['detection_conf']),
    );
  }

  factory CycleLog.fromLiveData(LiveData d) {
    return CycleLog(
      id: d.cycleId,
      ts: d.ts,
      nodeId: d.nodeId,
      moisturePct: d.moisturePct,
      waterPct: d.waterPct,
      cs: d.cs,
      cv: d.cv,
      ccombined: d.ccombined,
      alert: d.alert,
      detectionClass: d.detectionClass,
      detectionConf: d.detectionConf,
    );
  }
}