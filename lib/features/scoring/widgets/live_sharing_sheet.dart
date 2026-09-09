import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../local_scoring_provider.dart';
import '../scoring_provider.dart';

class LiveSharingSheet extends StatelessWidget {
  const LiveSharingSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LiveSharingSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localProv = context.watch<LocalScoringProvider>();
    final scoringProv = context.read<ScoringProvider>();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_tethering_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wi-Fi Live Sharing',
                      style: AppTextStyles.h3.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Live scoring over same Wi-Fi (No internet needed)',
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

          if (!localProv.isHosting) ...[
            // Not Hosting Yet
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.sensors_rounded, size: 48, color: AppColors.primary),
                  const SizedBox(height: 12),
                  const Text(
                    'Host Live Match on Local Wi-Fi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Start hosting to generate a simple 6-digit code. Spectators on the same Wi-Fi can enter the code to view this live scorecard in real-time.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppButton(
                    label: 'Start Host & Generate Code',
                    icon: Icons.play_arrow_rounded,
                    isFullWidth: true,
                    onPressed: () async {
                      final pin = await localProv.startHosting(scoringProv);
                      if (context.mounted && pin == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to start local server. Please ensure Wi-Fi is connected.')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ] else ...[
            // Active Hosting State
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Live Broadcasting Active',
                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${localProv.viewers.length} Viewers',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 6-digit PIN Box
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'VIEWER CONNECTION CODE',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPinDisplay(localProv.pinCode ?? '------'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy Code', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          if (localProv.pinCode != null) {
                            Clipboard.setData(ClipboardData(text: localProv.pinCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Connection code copied to clipboard!')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Host IP: ${localProv.hostIp ?? "Local Wi-Fi"}:${localProv.actualPort}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Connected Viewers List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Connected Viewers (${localProv.viewers.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (localProv.viewers.isNotEmpty)
                  Text(
                    'Read-Only',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (localProv.viewers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'Waiting for viewers to enter code on same Wi-Fi...',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontStyle: FontStyle.italic,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: localProv.viewers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final v = localProv.viewers[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.phone_android_rounded, size: 20, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v.deviceName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text(
                                  'IP: ${v.ip}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.person_remove_rounded, color: AppColors.danger, size: 20),
                            tooltip: 'Disconnect Viewer',
                            onPressed: () {
                              localProv.disconnectViewer(v.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 18),

            // Stop Hosting Button
            AppButton(
              label: 'Stop Live Sharing',
              icon: Icons.stop_circle_outlined,
              variant: AppButtonVariant.outline,
              isFullWidth: true,
              onPressed: () async {
                await localProv.stopHosting();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPinDisplay(String pin) {
    final digits = pin.padRight(6, '-').split('');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < digits.length; i++) ...[
          if (i == 3) const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('-', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Container(
            width: 40,
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Center(
              child: Text(
                digits[i],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
