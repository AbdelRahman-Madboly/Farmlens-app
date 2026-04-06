class NodeStatus {
  final String nodeId;
  final String mode;
  final int uptimeS;
  final int freeHeap;
  final int wifiClients;

  const NodeStatus({
    required this.nodeId,
    required this.mode,
    required this.uptimeS,
    required this.freeHeap,
    required this.wifiClients,
  });

  factory NodeStatus.fromJson(Map<String, dynamic> json) {
    return NodeStatus(
      nodeId: json['node_id']?.toString() ?? '',
      mode: json['mode']?.toString() ?? '',
      uptimeS: (json['uptime_s'] as num?)?.toInt() ?? 0,
      freeHeap: (json['free_heap'] as num?)?.toInt() ?? 0,
      wifiClients: (json['wifi_clients'] as num?)?.toInt() ?? 0,
    );
  }
}