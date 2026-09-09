import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../live_scoring_viewer_screen.dart';
import '../local_scoring_provider.dart';

class JoinMatchDialog extends StatefulWidget {
  const JoinMatchDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const JoinMatchDialog(),
    );
  }

  @override
  State<JoinMatchDialog> createState() => _JoinMatchDialogState();
}

class _JoinMatchDialogState extends State<JoinMatchDialog> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  bool _isLoading = false;
  bool _showAdvanced = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocalScoringProvider>().startDiscovery();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _attemptConnect(String pin, {String? manualIp}) async {
    final cleanPin = pin.replaceAll(RegExp(r'\D'), '').trim();
    if (cleanPin.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit connection code.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final localProv = context.read<LocalScoringProvider>();
    final success = await localProv.joinAsViewer(
      cleanPin,
      directHostIp: manualIp?.trim().isNotEmpty == true ? manualIp!.trim() : null,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.of(context).pop(); // Close dialog
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const LiveScoringViewerScreen(),
        ),
      );
    } else {
      setState(() {
        _errorMessage = localProv.viewerError ??
            'Could not find Host with this code on the Wi-Fi. Make sure both phones are connected to the same Wi-Fi network.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localProv = context.watch<LocalScoringProvider>();
    final discovered = localProv.discoveredMatches;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wifi_find_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Join Live Match', style: AppTextStyles.h3.copyWith(fontSize: 18)),
                        Text(
                          'Same Wi-Fi Network (Read-Only)',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Discovered Matches on Wi-Fi (if any)
              if (discovered.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.sensors_rounded, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      'Detected Nearby Match on Wi-Fi',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...discovered.map((b) => AppCard(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: AppColors.success.withValues(alpha: 0.08),
                      borderColor: AppColors.success.withValues(alpha: 0.3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.matchTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  '${b.battingTeamName ?? "Team"}: ${b.scoreRuns}/${b.scoreWickets} (${b.oversDisplay} ov)',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: _isLoading
                                ? null
                                : () {
                                    _pinController.text = b.pin;
                                    _attemptConnect(b.pin, manualIp: b.hostIp);
                                  },
                            child: const Text('Join', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
              ],

              // 6-digit Code Input
              const Text(
                'Enter 6-Digit Host Code',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  hintStyle: TextStyle(
                    letterSpacing: 8,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Advanced IP Toggle
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showAdvanced = !_showAdvanced;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showAdvanced ? 'Hide Advanced Options' : 'Advanced: Specify Host IP',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    Icon(
                      _showAdvanced ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      size: 16,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ],
                ),
              ),

              if (_showAdvanced) ...[
                const SizedBox(height: 10),
                AppTextField(
                  label: 'Host IP Address (Optional)',
                  hint: 'e.g. 192.168.1.45',
                  controller: _ipController,
                  keyboardType: TextInputType.datetime,
                ),
              ],

              // Error Message Banner
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Connect Button
              AppButton(
                label: _isLoading ? 'Connecting to Host...' : 'Connect to Live Match ➔',
                icon: _isLoading ? null : Icons.wifi_tethering_rounded,
                isLoading: _isLoading,
                isFullWidth: true,
                onPressed: _isLoading
                    ? null
                    : () => _attemptConnect(_pinController.text, manualIp: _ipController.text),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Make sure both phones are connected to the same Wi-Fi router or hotspot.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
