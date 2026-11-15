import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/social_login_buttons.dart';
import '../../../routes/app_routes.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  SettingsController get controller {
    if (!Get.isRegistered<SettingsController>()) {
      return Get.put(
        SettingsController(
          apiClient: Get.find<ApiClient>(),
          storageService: Get.find<StorageService>(),
        ),
      );
    }
    return Get.find<SettingsController>();
  }

  @override
  Widget build(BuildContext context) {
    final user = controller.user;
    final userName = user?['name'] ?? 'F-Tracker User';
    final userEmail = user?['email'] ?? 'user@example.com';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.canPop(context),
        title: const Text('Settings'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      gradient: AppColors.emeraldGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userEmail,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Offline & Cloud Sync Hub
            const Text(
              'Cloud Sync & Offline Storage',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildSyncCenter(context),
            const SizedBox(height: 24),

            // Connected Accounts Section
            const Text(
              'Connected Accounts',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildConnectedAccounts(context),
            const SizedBox(height: 24),

            // Security & Preferences Section
            const Text(
              'Preferences & Security',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.fingerprint_rounded, color: AppColors.primaryLight),
                    title: const Text('Biometric Lock (Face ID / Fingerprint)', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: const Text('Secure data when app opens', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    trailing: Obx(() => Switch(
                      value: controller.isBiometricEnabled.value,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => controller.toggleBiometric(val),
                    )),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  Obx(() => ListTile(
                    leading: const Icon(Icons.public_rounded, color: AppColors.accent),
                    title: const Text('Timezone', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: Text(controller.currentTimezone.value, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: () => _showTimezonePicker(context),
                  )),
                  const Divider(color: AppColors.border, height: 1),
                  ListTile(
                    leading: const Icon(Icons.category_outlined, color: AppColors.secondary),
                    title: const Text('Manage Categories', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: const Text('Organize income & expense categories', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: () => Get.toNamed(Routes.categories),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Log Out'),
              onPressed: () {
                AppHaptics.heavy();
                SnackbarService.dismissAll();
                final pending = controller.syncService.pendingCount.value;

                if (pending > 0) {
                  showDialog(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Row(
                        children: [
                          Icon(Icons.cloud_off_rounded, color: AppColors.warning, size: 22),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Unsynced Changes',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ),
                        ],
                      ),
                      content: Text(
                        'You have $pending offline item(s) waiting to sync to the server. If you log out now, these unsynced changes will be permanently discarded.\n\nDo you want to log out anyway?',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                          onPressed: () {
                            Navigator.of(dialogCtx).pop();
                            controller.logout();
                          },
                          child: const Text('Discard & Log Out'),
                        ),
                      ],
                    ),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text('Confirm Log Out', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                      content: const Text('Are you sure you want to log out of this account?', style: TextStyle(color: AppColors.textSecondary)),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                          onPressed: () {
                            Navigator.of(dialogCtx).pop();
                            controller.logout();
                          },
                          child: const Text('Log Out'),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // Danger Zone - Apple App Store Guideline 5.1.1(v) Compliant
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Danger Zone',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'You have the right to permanently delete your account and all transaction and category data at any time. This action cannot be undone.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.delete_forever_rounded, size: 18),
                    label: const Text('Permanently Delete Account', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      AppHaptics.heavy();
                      SnackbarService.dismissAll();

                      if (!controller.syncService.isOnline.value) {
                        SnackbarService.error(
                          'Cannot delete account while offline. Please connect to the internet to delete your account.',
                          title: 'Offline',
                        );
                        return;
                      }

                      showDialog(
                        context: context,
                        builder: (dialogCtx) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('Delete Account Permanently?', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          content: const Text(
                            'Are you sure you want to permanently delete this account?\n\nAll your transaction history, categories, and profile data will be permanently removed from the server and this device in compliance with privacy regulations. This action is irreversible.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogCtx).pop(),
                              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                              onPressed: () {
                                Navigator.of(dialogCtx).pop();
                                controller.deleteAccount();
                              },
                              child: const Text('Delete My Account'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncCenter(BuildContext context) {
    final syncService = controller.syncService;

    return Obx(() {
      final isOnline = syncService.isOnline.value;
      final isSyncing = syncService.isSyncing.value;
      final pendingCount = syncService.pendingCount.value;
      final lastSynced = syncService.lastSyncedAt.value;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOnline
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.warning.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Status Row
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? AppColors.income : AppColors.warning,
                    boxShadow: [
                      BoxShadow(
                        color: (isOnline ? AppColors.income : AppColors.warning).withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOnline ? 'Online • Connected to Server' : 'Offline Mode Active',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isOnline
                            ? 'Local & cloud storage automatically synchronized'
                            : 'All changes recorded locally & queued for sync',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.border, height: 24),

            // Metrics Details
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Offline Queue',
                    value: '$pendingCount item',
                    icon: Icons.pending_actions_rounded,
                    color: pendingCount > 0 ? AppColors.warning : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Local Cache',
                    value: '${controller.localTransactionCount} tx • ${controller.localCategoryCount} cat',
                    icon: Icons.sd_storage_rounded,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Last Synced Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Text(
                    'Last synced: ${lastSynced != null ? CurrencyFormatter.formatDate(lastSynced) : "Never"}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Feature explanation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.offline_bolt_rounded, size: 18, color: AppColors.primaryLight),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Seamless Offline Mode: Create, edit, and record transactions anytime without an internet connection. Data is safely saved on your device and synced automatically when back online.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sync Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isSyncing ? null : controller.triggerManualSync,
                      icon: isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.sync_rounded, size: 18),
                      label: Text(
                        isSyncing ? 'Syncing...' : 'Sync Now',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isSyncing ? null : controller.triggerFullResync,
                      icon: const Icon(Icons.cloud_download_rounded, size: 18),
                      label: const Text(
                        'Full Re-sync',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTimezonePicker(BuildContext context) {
    final timezones = [
      {'value': 'UTC', 'label': 'UTC (Universal Coordinated Time)'},
      {'value': 'Asia/Jakarta', 'label': 'Asia/Jakarta (WIB, UTC+7)'},
      {'value': 'Asia/Makassar', 'label': 'Asia/Makassar (WITA, UTC+8)'},
      {'value': 'Asia/Jayapura', 'label': 'Asia/Jayapura (WIT, UTC+9)'},
      {'value': 'Asia/Singapore', 'label': 'Asia/Singapore (SGT, UTC+8)'},
      {'value': 'Asia/Tokyo', 'label': 'Asia/Tokyo (JST, UTC+9)'},
      {'value': 'Europe/London', 'label': 'Europe/London (GMT/BST)'},
      {'value': 'America/New_York', 'label': 'America/New_York (EST/EDT)'},
      {'value': 'America/Los_Angeles', 'label': 'America/Los_Angeles (PST/PDT)'},
    ];

    Get.bottomSheet(
      Material(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Select Timezone',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: timezones.length,
                  itemBuilder: (context, index) {
                    final tz = timezones[index];
                    final isSelected = controller.currentTimezone.value == tz['value'];
                    return ListTile(
                      title: Text(tz['label']!, style: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      )),
                      trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                      onTap: () {
                        Get.back();
                        controller.updateTimezone(tz['value']!);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildConnectedAccounts(BuildContext context) {
    return Obx(() {
      final showApple = controller.isAppleAvailable.value;
      return Column(
        children: [
          _buildGoogleAccountCard(context),
          if (showApple) ...[
            const SizedBox(height: 12),
            _buildAppleAccountCard(context),
          ],
        ],
      );
    });
  }

  Widget _buildGoogleAccountCard(BuildContext context) {
    return Obx(() {
      final isLinked = controller.isGoogleLinked.value;
      final email = controller.googleEmail.value ?? (isLinked ? (controller.user?['email']?.toString() ?? '') : '');
      final isBinding = controller.isBindingGoogle.value;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: CustomPaint(
                      size: const Size(20, 20),
                      painter: GoogleLogoPainter(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Google Account',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isLinked ? AppColors.success : AppColors.warning).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (isLinked ? AppColors.success : AppColors.warning).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              isLinked ? 'Connected' : 'Not Linked',
                              style: TextStyle(
                                color: isLinked ? AppColors.success : AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLinked
                            ? (email.isNotEmpty ? email : 'Google account connected')
                            : 'Link Google account for seamless login',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (isLinked)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Google account active and linked',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: isBinding ? null : () => controller.bindGoogle(),
                  icon: isBinding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : CustomPaint(size: const Size(16, 16), painter: GoogleLogoPainter()),
                  label: Text(
                    isBinding ? 'Connecting...' : 'Connect Google',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildAppleAccountCard(BuildContext context) {
    return Obx(() {
      final isLinked = controller.isAppleLinked.value;
      final email = controller.appleEmail.value;
      final isBinding = controller.isBindingApple.value;
      final isUnbinding = controller.isUnbindingApple.value;
      final isAppleReg = controller.isAppleRegistered.value;
      final isGoogleLinked = controller.isGoogleLinked.value;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Icon(Icons.apple, color: Colors.black, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Apple ID',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isLinked ? AppColors.success : AppColors.warning).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (isLinked ? AppColors.success : AppColors.warning).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              isLinked ? 'Connected' : 'Not Connected',
                              style: TextStyle(
                                color: isLinked ? AppColors.success : AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLinked
                            ? (email != null && email.isNotEmpty ? email : 'Apple ID active and linked')
                            : 'Sign in quickly using your device Apple ID',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isAppleReg && !isGoogleLinked) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Account registered via Apple ID. Link Google first before managing or unbinding Apple to prevent account lockout.',
                        style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (isLinked)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Securely connected',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    onPressed: isUnbinding
                        ? null
                        : () => _confirmUnbindApple(context),
                    icon: isUnbinding
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                          )
                        : const Icon(Icons.link_off_rounded, size: 16),
                    label: Text(
                      isUnbinding ? 'Unbinding...' : 'Unbind Apple',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: isBinding ? null : () => controller.bindApple(),
                  icon: isBinding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.apple, size: 20, color: Colors.black),
                  label: Text(
                    isBinding ? 'Connecting...' : 'Connect Apple',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  void _confirmUnbindApple(BuildContext context) {
    AppHaptics.heavy();
    SnackbarService.dismissAll();

    if (controller.isAppleRegistered.value && !controller.isGoogleLinked.value) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Cannot Unbind Apple ID', style: TextStyle(color: AppColors.textPrimary)),
          content: const Text(
            'This account was registered via Apple ID. You must link your Google account first to prevent permanent account lockout.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Unlink Apple ID', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to unlink your Apple ID from this account? You will need to use your other sign-in methods.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.unbindApple();
            },
            child: const Text('Unbind'),
          ),
        ],
      ),
    );
  }
}
