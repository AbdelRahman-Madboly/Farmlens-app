import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/live_data.dart';
import '../providers/connection_provider.dart';
import '../providers/live_provider.dart';
import '../providers/settings_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/formatters.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _lastAlertCycleId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPolling();
    });
  }

  void _startPolling() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final live = Provider.of<LiveProvider>(context, listen: false);
    if (settings.deviceBaseUrl.isNotEmpty) {
      live.startPolling(ApiService(settings.deviceBaseUrl));
    }
  }

  void _manualRefresh() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final live = Provider.of<LiveProvider>(context, listen: false);
    if (settings.deviceBaseUrl.isNotEmpty) {
      live.stopPolling();
      live.startPolling(ApiService(settings.deviceBaseUrl));
    }
  }

  void _checkAndShowAlertSnackBar(LiveData data) {
    if (data.alert &&
        data.cycleId.isNotEmpty &&
        data.cycleId != _lastAlertCycleId) {
      _lastAlertCycleId = data.cycleId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠ Disease Alert: ${formatDetectionClass(data.detectionClass)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: FarmLensColors.alert,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 120,
              left: 16,
              right: 16,
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    Provider.of<LiveProvider>(context, listen: false).stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LiveProvider, ConnectionProvider>(
      builder: (context, liveProvider, connProvider, _) {
        final data = liveProvider.latest;
        final isEmpty = data.cycleId.isEmpty;
        final isError = connProvider.state == DeviceConnectionState.error;

        _checkAndShowAlertSnackBar(data);

        return Scaffold(
          backgroundColor: FarmLensColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // ── App Bar ──────────────────────────────
                _AppBar(
                  nodeId: data.nodeId,
                  onRefresh: _manualRefresh,
                ),

                // ── Body ─────────────────────────────────
                Expanded(
                  child: (isEmpty || isError)
                      ? _ErrorState(connProvider: connProvider, data: data)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Section 1: Status row
                              _StatusCard(
                                isOffline: liveProvider.isOffline,
                                ts: data.ts,
                                cycleId: data.cycleId,
                              ),
                              const SizedBox(height: 12),

                              // Section 2: Alert banner
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: data.alert
                                    ? _AlertBanner(data: data)
                                    : const SizedBox.shrink(),
                              ),
                              if (data.alert) const SizedBox(height: 12),

                              // Section 3: Gauge
                              _GaugeCard(data: data),
                              const SizedBox(height: 12),

                              // Section 4: Sensor row
                              Row(
                                children: [
                                  Expanded(
                                    child: _SensorCard(
                                      title: 'Soil Moisture',
                                      pct: data.moisturePct,
                                      stress: data.moistureStress == 1,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _SensorCard(
                                      title: 'Water Level',
                                      pct: data.waterPct,
                                      stress: data.waterStress == 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Section 5: Detection card
                              _DetectionCard(data: data),
                              const SizedBox(height: 16),
                            ],
                          ),
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
// App Bar
// ─────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final String nodeId;
  final VoidCallback onRefresh;

  const _AppBar({required this.nodeId, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FarmLensColors.card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'FarmLens',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: FarmLensColors.textPrimary,
            ),
          ),
          Row(
            children: [
              if (nodeId.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: FarmLensColors.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    nodeId,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: FarmLensColors.primary,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRefresh,
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 22,
                  color: FarmLensColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section 1 – Status Card
// ─────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final bool isOffline;
  final int ts;
  final String cycleId;

  const _StatusCard({
    required this.isOffline,
    required this.ts,
    required this.cycleId,
  });

  String _cycleNumber(String id) {
    if (id.isEmpty) return '';
    final parts = id.split('-');
    if (parts.length >= 3) return '#${parts[parts.length - 2]}';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final cycleNum = _cycleNumber(cycleId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: FarmLensColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FarmLensColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOffline
                      ? FarmLensColors.alert
                      : FarmLensColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isOffline ? 'Node offline' : 'Connected',
                style: const TextStyle(
                  fontSize: 11,
                  color: FarmLensColors.textPrimary,
                ),
              ),
              if (cycleNum.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  'Cycle $cycleNum',
                  style: const TextStyle(
                    fontSize: 11,
                    color: FarmLensColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          Text(
            ts == 0 ? '—' : 'Updated ${timeAgo(ts)}',
            style: const TextStyle(
              fontSize: 11,
              color: FarmLensColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section 2 – Alert Banner
// ─────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  final LiveData data;
  const _AlertBanner({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('alert-banner'),
      decoration: const BoxDecoration(
        color: Color(0xFFFCEBEB),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border(
          left: BorderSide(color: FarmLensColors.alert, width: 4),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠ Disease Alert',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: FarmLensColors.alert,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDetectionClass(data.detectionClass),
                  style: const TextStyle(
                    fontSize: 12,
                    color: FarmLensColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          _ScorePill(value: data.ccombined, color: FarmLensColors.alert),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section 3 – Gauge Card
// ─────────────────────────────────────────────

class _GaugeCard extends StatelessWidget {
  final LiveData data;
  const _GaugeCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: FarmLensColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FarmLensColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          _AnimatedGauge(value: data.ccombined),
          const SizedBox(height: 8),
          const Text(
            'Combined Score',
            style: TextStyle(
              fontSize: 12,
              color: FarmLensColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cv ${data.cv.toStringAsFixed(2)}  ·  Cs ${data.cs.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 11,
              color: FarmLensColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedGauge extends StatefulWidget {
  final double value;
  const _AnimatedGauge({required this.value});

  @override
  State<_AnimatedGauge> createState() => _AnimatedGaugeState();
}

class _AnimatedGaugeState extends State<_AnimatedGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _animation = Tween<double>(
        begin: _previousValue,
        end: widget.value,
      ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final v = _animation.value.clamp(0.0, 1.0);
        final color = ccombinedColor(v);
        return SizedBox(
          width: 180,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(180, 110),
                painter: _GaugePainter(value: v, color: color),
              ),
              Positioned(
                bottom: 8,
                child: Text(
                  v.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  static const double strokeWidth = 14;

  const _GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 10;
    final radius = (size.width / 2) - (strokeWidth / 2);

    final trackPaint = Paint()
      ..color = const Color(0xFFE8E8E4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      math.pi,
      math.pi,
      false,
      trackPaint,
    );

    if (value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        math.pi,
        math.pi * value,
        false,
        valuePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color;
}

// ─────────────────────────────────────────────
// Section 4 – Sensor Card
// ─────────────────────────────────────────────

class _SensorCard extends StatelessWidget {
  final String title;
  final double pct;
  final bool stress;

  const _SensorCard({
    required this.title,
    required this.pct,
    required this.stress,
  });

  @override
  Widget build(BuildContext context) {
    final color = stress ? FarmLensColors.alert : FarmLensColors.primary;
    final clampedPct = pct.clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FarmLensColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FarmLensColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: FarmLensColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${clampedPct.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: clampedPct / 100,
                backgroundColor: FarmLensColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              stress ? 'STRESS' : 'OK',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section 5 – Detection Card
// ─────────────────────────────────────────────

class _DetectionCard extends StatelessWidget {
  final LiveData data;
  const _DetectionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final disease = isDisease(data.detectionClass);
    final pillBg =
        disease ? const Color(0xFFFCEBEB) : const Color(0xFFE1F5EE);
    final pillText =
        disease ? FarmLensColors.alert : FarmLensColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: FarmLensColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FarmLensColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Latest Detection',
            style: TextStyle(
              fontSize: 11,
              color: FarmLensColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatDetectionClass(data.detectionClass),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: FarmLensColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeAgo(data.ts),
                      style: const TextStyle(
                        fontSize: 11,
                        color: FarmLensColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(data.detectionConf * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: pillText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section 6 – Error State
// ─────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final ConnectionProvider connProvider;
  final LiveData data;

  const _ErrorState({required this.connProvider, required this.data});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: FarmLensColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No data from device',
              style: TextStyle(
                fontSize: 16,
                color: FarmLensColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.ts == 0
                  ? 'Last seen: Never'
                  : 'Last seen: ${timeAgo(data.ts)}',
              style: const TextStyle(
                fontSize: 12,
                color: FarmLensColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check device is on the same WiFi network',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: FarmLensColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed:
                  connProvider.state == DeviceConnectionState.connecting
                      ? null
                      : () =>
                          connProvider.connect(settings.deviceBaseUrl),
              icon: connProvider.state == DeviceConnectionState.connecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FarmLensColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared – Score Pill
// ─────────────────────────────────────────────

class _ScorePill extends StatelessWidget {
  final double value;
  final Color color;
  const _ScorePill({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value.toStringAsFixed(2),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}