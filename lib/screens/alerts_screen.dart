import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/cycle_log.dart';
import '../providers/live_provider.dart';
import '../theme.dart';

// ─────────────────────────────────────────────
// Helpers (shared with dashboard)
// ─────────────────────────────────────────────

String _formatDetectionClass(String cls) {
  if (cls.isEmpty || cls == 'none') return 'No Detection';
  final parts = cls.split('_');
  if (parts.length < 2) return cls;
  final crop = parts[0];
  final rest = parts
      .sublist(1)
      .map((w) => w.isEmpty
          ? ''
          : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
  return '$crop — $rest';
}

String _timeAgo(int ts) {
  if (ts == 0) return 'never';
  final diff = DateTime.now().millisecondsSinceEpoch ~/ 1000 - ts;
  if (diff < 0) return 'just now';
  if (diff < 60) return '${diff}s ago';
  if (diff < 3600) return '${diff ~/ 60}m ago';
  return '${diff ~/ 3600}h ago';
}

Color _ccombinedColor(double v) {
  if (v < 0.4) return FarmLensColors.primary;
  if (v < 0.65) return FarmLensColors.amber;
  return FarmLensColors.alert;
}

// ─────────────────────────────────────────────
// Alerts Screen
// ─────────────────────────────────────────────

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LiveProvider>(context, listen: false).markAlertsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LiveProvider>(
      builder: (context, liveProvider, _) {
        final alerts = liveProvider.alerts;
        final count = alerts.length;

        return Scaffold(
          backgroundColor: FarmLensColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // ── App Bar ────────────────────────────────
                Container(
                  color: FarmLensColors.card,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Text(
                        'Alert Feed',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: FarmLensColors.textPrimary,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: FarmLensColors.alert,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              count > 9 ? '9+' : '$count',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: FarmLensColors.border),

                // ── Body ──────────────────────────────────
                Expanded(
                  child: alerts.isEmpty
                      ? _EmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: alerts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) =>
                              _AlertCard(alert: alerts[i]),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 56,
            color: FarmLensColors.primary,
          ),
          SizedBox(height: 16),
          Text(
            'No alerts today',
            style: TextStyle(
              fontSize: 18,
              color: FarmLensColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'All crops are healthy',
            style: TextStyle(
              fontSize: 14,
              color: FarmLensColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Alert Card
// ─────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final CycleLog alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/log/${alert.id}'),
      child: Container(
        decoration: const BoxDecoration(
          color: FarmLensColors.card,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          border: Border(
            left: BorderSide(color: FarmLensColors.alert, width: 4),
            top: BorderSide(color: FarmLensColors.border, width: 0.5),
            right: BorderSide(color: FarmLensColors.border, width: 0.5),
            bottom: BorderSide(color: FarmLensColors.border, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left content ──────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Detection class + time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatDetectionClass(alert.detectionClass),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: FarmLensColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _timeAgo(alert.ts),
                        style: const TextStyle(
                          fontSize: 11,
                          color: FarmLensColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Score + sensor readings
                  Row(
                    children: [
                      _ScorePill(value: alert.ccombined),
                      const SizedBox(width: 8),
                      Text(
                        '💧 ${alert.moisturePct.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: FarmLensColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '🌊 ${alert.waterPct.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: FarmLensColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // ── Image placeholder ─────────────────────
            Container(
              width: 48,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0EC),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.image_outlined,
                size: 20,
                color: Color(0xFFB4B2A9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Score Pill
// ─────────────────────────────────────────────

class _ScorePill extends StatelessWidget {
  final double value;
  const _ScorePill({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _ccombinedColor(value),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value.toStringAsFixed(2),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}