import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/connection_provider.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';
import '../constants.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '80');
  List<String> _recentUrls = [];
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(FarmLensConstants.prefKeyBaseUrl) ?? '';
    if (saved.isNotEmpty) {
      final uri = Uri.tryParse(saved);
      if (uri != null) {
        _ipController.text = uri.host;
        _portController.text = uri.port.toString();
      }
      if (mounted) {
        setState(() => _recentUrls = [saved]);
      }
    }
  }

  void _fillFromRecent(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      _ipController.text = uri.host;
      _portController.text = uri.port.toString();
    }
  }

  String? _validateIp(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter an IP address';
    final parts = value.trim().split('.');
    if (parts.length != 4) return 'Enter a valid IP (e.g. 192.168.1.22)';
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null || n < 0 || n > 255) {
        return 'Enter a valid IP (e.g. 192.168.1.22)';
      }
    }
    return null;
  }

  String? _validatePort(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter a port';
    final n = int.tryParse(value.trim());
    if (n == null || n < 1 || n > 65535) return 'Valid port: 1–65535';
    return null;
  }

  Future<void> _handleConnect() async {
    if (!_formKey.currentState!.validate()) return;

    final ip = _ipController.text.trim();
    final port = _portController.text.trim();
    final baseUrl = 'http://$ip:$port';

    setState(() => _isConnecting = true);

    final connProvider =
        Provider.of<ConnectionProvider>(context, listen: false);
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);

    final success = await connProvider.connect(baseUrl);

    if (!mounted) return;
    setState(() => _isConnecting = false);

    if (success) {
      await settingsProvider.saveDeviceUrl(baseUrl);
      if (!mounted) return;
      context.go('/main');
    } else {
      final err =
          connProvider.errorMessage ?? 'Could not connect to device';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: FarmLensColors.alert,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
          color: FarmLensColors.textSecondary, fontSize: 14),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: FarmLensColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: FarmLensColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            const BorderSide(color: FarmLensColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: FarmLensColors.alert),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            const BorderSide(color: FarmLensColors.alert, width: 1.5),
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmLensColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),

                  // ── Top Section ──────────────────────────────────
                  const Icon(
                    Icons.eco_rounded,
                    size: 48,
                    color: FarmLensColors.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'FarmLens',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: FarmLensColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Edge AI Crop Monitoring',
                    style: TextStyle(
                      fontSize: 14,
                      color: FarmLensColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Form Card ────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: FarmLensColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: FarmLensColors.border, width: 0.5),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // IP
                        const Text(
                          'Device IP Address',
                          style: TextStyle(
                            fontSize: 12,
                            color: FarmLensColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _ipController,
                          keyboardType: TextInputType.url,
                          validator: _validateIp,
                          style: const TextStyle(
                            fontSize: 14,
                            color: FarmLensColors.textPrimary,
                          ),
                          decoration: _fieldDecoration('192.168.1.100'),
                        ),
                        const SizedBox(height: 12),

                        // Port
                        const Text(
                          'Port',
                          style: TextStyle(
                            fontSize: 12,
                            color: FarmLensColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _portController,
                          keyboardType: TextInputType.number,
                          validator: _validatePort,
                          style: const TextStyle(
                            fontSize: 14,
                            color: FarmLensColors.textPrimary,
                          ),
                          decoration: _fieldDecoration('80'),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'ESP32: port 80 · Raspberry Pi: port 8000',
                          style: TextStyle(
                            fontSize: 11,
                            color: FarmLensColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Connect Button ───────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isConnecting ? null : _handleConnect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FarmLensColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            FarmLensColors.primary.withAlpha(153),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isConnecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Connect →',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  // ── Recent IPs ───────────────────────────────────
                  if (_recentUrls.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Recent:',
                          style: TextStyle(
                            fontSize: 12,
                            color: FarmLensColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            children: _recentUrls.map((url) {
                              final uri = Uri.tryParse(url);
                              final label = uri != null
                                  ? '${uri.host}:${uri.port}'
                                  : url;
                              return ActionChip(
                                label: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: FarmLensColors.primary,
                                  ),
                                ),
                                onPressed: () => _fillFromRecent(url),
                                backgroundColor: Colors.transparent,
                                side: const BorderSide(
                                    color: FarmLensColors.primary,
                                    width: 1),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ── Footer ───────────────────────────────────────
                  const SizedBox(height: 32),
                  const Text(
                    'Suez Canal University · IC EISIS 2026',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: FarmLensColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}