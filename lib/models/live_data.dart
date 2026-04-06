class LiveData {
  final int ts;
  final String nodeId;
  final int moistureRaw;
  final double moisturePct;
  final int waterRaw;
  final double waterPct;
  final int moistureStress;
  final int waterStress;
  final double cs;
  final double cv;
  final double ccombined;
  final bool alert;
  final String detectionClass;
  final double detectionConf;
  final String cycleId;

  const LiveData({
    required this.ts,
    required this.nodeId,
    required this.moistureRaw,
    required this.moisturePct,
    required this.waterRaw,
    required this.waterPct,
    required this.moistureStress,
    required this.waterStress,
    required this.cs,
    required this.cv,
    required this.ccombined,
    required this.alert,
    required this.detectionClass,
    required this.detectionConf,
    required this.cycleId,
  });

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory LiveData.fromJson(Map<String, dynamic> json) {
    return LiveData(
      ts: (json['ts'] as num?)?.toInt() ?? 0,
      nodeId: json['node_id']?.toString() ?? '',
      moistureRaw: (json['moisture_raw'] as num?)?.toInt() ?? 0,
      moisturePct: _d(json['moisture_pct']),
      waterRaw: (json['water_raw'] as num?)?.toInt() ?? 0,
      waterPct: _d(json['water_pct']),
      moistureStress: (json['moisture_stress'] as num?)?.toInt() ?? 0,
      waterStress: (json['water_stress'] as num?)?.toInt() ?? 0,
      cs: _d(json['cs']),
      cv: _d(json['cv']),
      ccombined: _d(json['ccombined']),
      alert: json['alert'] == true,
      detectionClass: json['detection_class']?.toString() ?? '',
      detectionConf: _d(json['detection_conf']),
      cycleId: json['cycle_id']?.toString() ?? '',
    );
  }

  factory LiveData.empty() {
    return const LiveData(
      ts: 0,
      nodeId: '',
      moistureRaw: 0,
      moisturePct: 0.0,
      waterRaw: 0,
      waterPct: 0.0,
      moistureStress: 0,
      waterStress: 0,
      cs: 0.0,
      cv: 0.0,
      ccombined: 0.0,
      alert: false,
      detectionClass: '',
      detectionConf: 0.0,
      cycleId: '',
    );
  }
}