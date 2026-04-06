import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/cycle_log.dart';
import '../providers/log_provider.dart';
import '../theme.dart';
import '../utils/formatters.dart';

class LogDetailScreen extends StatelessWidget {
  final String cycleId;
  const LogDetailScreen({super.key, required this.cycleId});

  @override
  Widget build(BuildContext context) {
    final logProvider = Provider.of<LogProvider>(context, listen: false);
    final CycleLog? cycle =
        logProvider.cycles.where((c) => c.id == cycleId).firstOrNull;

    if (cycle == null) {
      return const Scaffold(
        backgroundColor: FarmLensColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _AppBar(title: 'Detection Details'),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 48,
                          color: FarmLensColors.textSecondary),
                      SizedBox(height: 12),
                      Text(
                        'Cycle not found',
                        style: TextStyle(
                          fontSize: 16,
                          color: FarmLensColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final disease = isDisease(cycle.detectionClass);

    return Scaffold(
      backgroundColor: FarmLensColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _AppBar(title: 'Detection Details'),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Image Placeholder ──────────────────
                    Container(
                      width: double.infinity,
                      height: 200,
                      margin: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F0EC),
                        borderRadius:
                            BorderRadius.all(Radius.circular(12)),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined,
                              size: 48, color: Color(0xFFB4B2A9)),
                          SizedBox(height: 8),
                          Text(
                            'Detection image — available in Phase 2',
                            style: TextStyle(
                              fontSize: 11,
                              color: FarmLensColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Detection ─────────────────────
                          const _SectionHeader('Detection'),
                          _InfoCard(rows: [
                            _InfoRowData(
                              label: 'Class',
                              value: formatDetectionClass(
                                  cycle.detectionClass),
                            ),
                            _InfoRowData(
                              label: 'Confidence',
                              valueWidget: _ConfPill(
                                  pct: cycle.detectionConf,
                                  disease: disease),
                            ),
                            _InfoRowData(
                              label: 'Combined Score',
                              valueWidget:
                                  _ScorePill(value: cycle.ccombined),
                            ),
                            _InfoRowData(
                              label: 'Alert',
                              valueWidget: Text(
                                cycle.alert ? 'YES 🔴' : 'No 🟢',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: cycle.alert
                                      ? FarmLensColors.alert
                                      : FarmLensColors.primary,
                                ),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 20),

                          // ── Sensors ────────────────────────
                          const _SectionHeader('Sensors'),
                          _InfoCard(rows: [
                            _InfoRowData(
                              label: 'Soil Moisture',
                              value:
                                  '${cycle.moisturePct.toStringAsFixed(1)}%',
                              valueColor: cycle.moisturePct < 30
                                  ? FarmLensColors.alert
                                  : FarmLensColors.primary,
                            ),
                            _InfoRowData(
                              label: 'Water Level',
                              value:
                                  '${cycle.waterPct.toStringAsFixed(1)}%',
                              valueColor: cycle.waterPct < 20
                                  ? FarmLensColors.alert
                                  : FarmLensColors.primary,
                            ),
                            _InfoRowData(
                              label: 'Moisture Stress',
                              valueWidget: _StressLabel(
                                  stress: cycle.moisturePct < 30),
                            ),
                            _InfoRowData(
                              label: 'Water Stress',
                              valueWidget: _StressLabel(
                                  stress: cycle.waterPct < 20),
                            ),
                            _InfoRowData(
                              label: 'Cs Score',
                              value: cycle.cs.toStringAsFixed(3),
                            ),
                          ]),
                          const SizedBox(height: 20),

                          // ── Fusion ─────────────────────────
                          const _SectionHeader('Fusion'),
                          _InfoCard(rows: [
                            _InfoRowData(
                              label: 'Cv (visual)',
                              value: cycle.cv.toStringAsFixed(3),
                            ),
                            _InfoRowData(
                              label: 'Cs (sensor)',
                              value: cycle.cs.toStringAsFixed(3),
                            ),
                            const _InfoRowData(
                                label: 'w1', value: '0.60'),
                            const _InfoRowData(
                                label: 'w2', value: '0.40'),
                            _InfoRowData(
                              label: 'Ccombined',
                              valueWidget:
                                  _ScorePill(value: cycle.ccombined),
                            ),
                          ]),
                          const SizedBox(height: 20),

                          // ── Traceability ───────────────────
                          const _SectionHeader('Traceability'),
                          _InfoCard(rows: [
                            _InfoRowData(
                              label: 'Cycle ID',
                              valueWidget: SelectableText(
                                cycle.id,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: FarmLensColors.textPrimary,
                                ),
                              ),
                            ),
                            _InfoRowData(
                              label: 'Node',
                              value: cycle.nodeId,
                            ),
                            _InfoRowData(
                              label: 'Timestamp',
                              value: formatDateTime(cycle.ts),
                            ),
                          ]),
                          const SizedBox(height: 20),

                          // ── ETRACE Badge ───────────────────
                          const Center(child: _EtraceBadge()),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final String title;
  const _AppBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FarmLensColors.card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: FarmLensColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: FarmLensColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: FarmLensColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _InfoRowData {
  final String label;
  final String? value;
  final Color? valueColor;
  final Widget? valueWidget;
  const _InfoRowData(
      {required this.label, this.value, this.valueColor, this.valueWidget});
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRowData> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FarmLensColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FarmLensColors.border, width: 0.5),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        row.label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: FarmLensColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: row.valueWidget ??
                            Text(
                              row.value ?? '—',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 13,
                                color: row.valueColor ??
                                    FarmLensColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              if (i < rows.length - 1)
                const Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: FarmLensColors.border,
                    indent: 14,
                    endIndent: 14),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final double value;
  const _ScorePill({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ccombinedColor(value),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value.toStringAsFixed(2),
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}

class _ConfPill extends StatelessWidget {
  final double pct;
  final bool disease;
  const _ConfPill({required this.pct, required this.disease});

  @override
  Widget build(BuildContext context) {
    final bg =
        disease ? const Color(0xFFFCEBEB) : const Color(0xFFE1F5EE);
    final fg = disease ? FarmLensColors.alert : FarmLensColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        '${(pct * 100).toStringAsFixed(0)}%',
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _StressLabel extends StatelessWidget {
  final bool stress;
  const _StressLabel({required this.stress});

  @override
  Widget build(BuildContext context) {
    return Text(
      stress ? 'Yes' : 'No',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: stress ? FarmLensColors.alert : FarmLensColors.primary,
      ),
    );
  }
}

class _EtraceBadge extends StatelessWidget {
  const _EtraceBadge();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFFE1F5EE),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, size: 14, color: Color(0xFF0F6E56)),
              SizedBox(width: 6),
              Text(
                'ETRACE Format Compatible',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F6E56),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}