import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/snackbar_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/category_icon_helper.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';

class TransactionCard extends GetView<TransactionController> {
  final TransactionModel transaction;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final catColor = _parseColor(transaction.category?.color ?? (isIncome ? '#10B981' : '#F43F5E'));
    final catIcon = CategoryIconHelper.getIconData(
      transaction.category?.icon,
      transaction.category?.name ?? (isIncome ? 'Income' : 'Expense'),
    );

    return Dismissible(
      key: ValueKey('tx_${transaction.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        AppHaptics.heavy();
        SnackbarService.dismissAll();
        final confirm = await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Delete Transaction', style: TextStyle(color: AppColors.textPrimary)),
            content: Text(
              'Are you sure you want to delete "${transaction.description}" of ${CurrencyFormatter.format(transaction.amount)}?',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogCtx).pop(false), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          if (onDelete != null) {
            onDelete!();
          } else {
            controller.deleteTransaction(transaction);
          }
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap ?? () => _showDetailModal(context),
            child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Category Icon Capsule
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: catColor.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Icon(
                      catIcon,
                      color: catColor,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Description & Category / Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description.isNotEmpty
                            ? transaction.description
                            : (transaction.category?.name ?? 'Transaction'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (transaction.category != null) ...[
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      catIcon,
                                      size: 11,
                                      color: catColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        transaction.category!.name,
                                        style: TextStyle(
                                          color: catColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            CurrencyFormatter.formatTransactionDate(transaction.date),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          if (!isIncome && (transaction.linkedIncomeDescription != null || transaction.linkedIncomeId != null)) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.link_rounded, size: 10, color: AppColors.primary),
                                  if (transaction.linkedIncomeDate != null) ...[
                                    const SizedBox(width: 2.5),
                                    Text(
                                      CurrencyFormatter.formatShortDate(transaction.linkedIncomeDate),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          if (transaction.isPendingSync) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cloud_upload_outlined, size: 10, color: AppColors.warning),
                                  SizedBox(width: 3),
                                  Text(
                                    'Offline',
                                    style: TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Amount
                Text(
                  '${isIncome ? "+" : "-"}${CurrencyFormatter.format(transaction.amount)}',
                  style: TextStyle(
                    color: isIncome ? AppColors.income : AppColors.expense,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  void _showDetailModal(BuildContext context) {
    AppHaptics.selection();
    controller.loadTransactionDetail(transaction);
    Get.bottomSheet(
      TransactionDetailSheet(
        initialTransaction: transaction,
        onDelete: onDelete,
      ),
      isScrollControlled: true,
    );
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

class TransactionDetailSheet extends GetView<TransactionController> {
  final TransactionModel initialTransaction;
  final VoidCallback? onDelete;

  const TransactionDetailSheet({
    super.key,
    required this.initialTransaction,
    this.onDelete,
  });

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Obx(() {
          final isMatchingTx = controller.selectedDetailTx.value?.id == initialTransaction.id;
          final currentTx = isMatchingTx ? controller.selectedDetailTx.value! : initialTransaction;
          final isLoadingDetail = controller.isLoadingDetail.value && isMatchingTx;

          final isIncome = currentTx.isIncome;
          final catColor = _parseColor(currentTx.category?.color ?? (isIncome ? '#10B981' : '#F43F5E'));
          final catIcon = CategoryIconHelper.getIconData(
            currentTx.category?.icon,
            currentTx.category?.name ?? (isIncome ? 'Income' : 'Expense'),
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar: Drag Handle & Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transaction Details',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Amount Card
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isIncome ? AppColors.income : AppColors.expense).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                currentTx.type.toUpperCase(),
                                style: TextStyle(
                                  color: isIncome ? AppColors.income : AppColors.expense,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${isIncome ? "+" : "-"}${CurrencyFormatter.format(currentTx.amount)}',
                              style: TextStyle(
                                color: isIncome ? AppColors.income : AppColors.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (currentTx.description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                currentTx.description,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Detail items
                      _buildDetailRow(
                        icon: catIcon,
                        label: 'Category',
                        value: currentTx.category?.name ?? 'General',
                        color: catColor,
                      ),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Transaction Date',
                        value: CurrencyFormatter.formatDisplayDate(currentTx.date),
                      ),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        icon: Icons.access_time_rounded,
                        label: 'Created At',
                        value: CurrencyFormatter.formatFullTimestamp(currentTx.createdAt),
                      ),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        icon: currentTx.isPendingSync ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                        label: 'Status',
                        value: currentTx.isPendingSync ? 'Offline (Pending Sync)' : 'Synced',
                        color: currentTx.isPendingSync ? AppColors.warning : AppColors.success,
                      ),

                      // SECTION: Income Burn-Down & Linked Expenses
                      if (isIncome) ...[
                        const SizedBox(height: 16),
                        _buildIncomeBurnDownSection(currentTx, isLoadingDetail),
                      ],

                      // SECTION: Expense Funded By Linked Income
                      if (!isIncome && (currentTx.linkedIncomeId != null || currentTx.linkedIncomeDetails != null)) ...[
                        const SizedBox(height: 16),
                        _buildExpenseFundingSection(currentTx),
                      ],
                    ],
                  ),
                ),
              ),

              // Sticky Bottom Action Bar (Edit & Delete)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.7))),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Get.back();
                          Get.toNamed('/transactions/edit', arguments: currentTx);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error.withValues(alpha: 0.15),
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Get.back();
                          if (onDelete != null) {
                            onDelete!();
                          } else {
                            controller.deleteTransaction(currentTx);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildIncomeBurnDownSection(TransactionModel currentTx, bool isLoadingDetail) {
    final total = currentTx.amount;
    final used = currentTx.totalUsed ?? 0.0;
    final remaining = currentTx.remainingAmount ?? (total - used);
    final pct = currentTx.percentageUsed ?? (total > 0 ? (used / total) * 100 : 0.0);
    final linkedExps = currentTx.linkedExpenses ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.income.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.income.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.income),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Income Burn-down Status',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (pct >= 100 ? AppColors.expense : AppColors.income).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${pct.toStringAsFixed(0)}% Used',
                  style: TextStyle(
                    color: pct >= 100 ? AppColors.expense : AppColors.income,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3-Metric Stats Row
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  label: 'Total Income',
                  value: CurrencyFormatter.format(total),
                  color: AppColors.textPrimary,
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.border),
              Expanded(
                child: _buildMiniStat(
                  label: 'Total Used',
                  value: CurrencyFormatter.format(used),
                  color: AppColors.expense,
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.border),
              Expanded(
                child: _buildMiniStat(
                  label: 'Remaining',
                  value: CurrencyFormatter.format(remaining),
                  color: remaining < 0 ? AppColors.expense : AppColors.income,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 100 ? AppColors.expense : AppColors.income,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),

          // Child Expenses List ("Dipake apa aja")
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expenses Funded (${linkedExps.length})',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isLoadingDetail)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (linkedExps.isNotEmpty) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: linkedExps.length,
              separatorBuilder: (_, _) => const Divider(color: AppColors.border, height: 12),
              itemBuilder: (context, index) {
                final exp = linkedExps[index];
                final expCatColor = _parseColor(exp.category?.color ?? '#F43F5E');
                final expCatIcon = CategoryIconHelper.getIconData(
                  exp.category?.icon,
                  exp.category?.name ?? 'Expense',
                );

                return Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: expCatColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(expCatIcon, color: expCatColor, size: 16),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exp.description.isNotEmpty ? exp.description : (exp.category?.name ?? 'Expense'),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.formatTransactionDate(exp.date),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '-${CurrencyFormatter.format(exp.amount)}',
                      style: const TextStyle(
                        color: AppColors.expense,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ] else if (isLoadingDetail) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'Loading funded expenses...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              alignment: Alignment.center,
              child: const Text(
                'No expenses linked to this income yet.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpenseFundingSection(TransactionModel currentTx) {
    final details = currentTx.linkedIncomeDetails;
    final parentTitle = currentTx.linkedIncomeDescription ?? details?['description'] ?? 'Linked Income';
    final parentAmount = (details?['amount'] as num?)?.toDouble();
    final parentUsed = (details?['totalUsed'] as num?)?.toDouble();
    final parentRemaining = (details?['remainingAmount'] as num?)?.toDouble();

    DateTime? parentDate = currentTx.linkedIncomeDate;
    if (parentDate == null && details?['date'] != null) {
      final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(details!['date'].toString());
      if (match != null) {
        parentDate = DateTime(int.parse(match.group(1)!), int.parse(match.group(2)!), int.parse(match.group(3)!));
      }
    }
    if (parentDate == null && currentTx.linkedIncomeId != null && Get.isRegistered<StorageService>()) {
      final cached = Get.find<StorageService>().cachedTransactions;
      for (final c in cached) {
        if (c is Map && (c['_id'] == currentTx.linkedIncomeId || c['id'] == currentTx.linkedIncomeId)) {
          final dStr = (c['date'] ?? c['createdAt'])?.toString();
          if (dStr != null) {
            final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(dStr);
            if (match != null) {
              parentDate = DateTime(int.parse(match.group(1)!), int.parse(match.group(2)!), int.parse(match.group(3)!));
              break;
            }
          }
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.link_rounded, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              const Text(
                'Funding Income Source',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  parentTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (parentDate != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event_rounded, size: 11, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        CurrencyFormatter.formatTransactionDate(parentDate),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (parentAmount != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    label: 'Income Total',
                    value: CurrencyFormatter.format(parentAmount),
                    color: AppColors.textPrimary,
                  ),
                ),
                if (parentUsed != null) ...[
                  Container(width: 1, height: 28, color: AppColors.border),
                  Expanded(
                    child: _buildMiniStat(
                      label: 'Already Used',
                      value: CurrencyFormatter.format(parentUsed),
                      color: AppColors.expense,
                    ),
                  ),
                ],
                if (parentRemaining != null) ...[
                  Container(width: 1, height: 28, color: AppColors.border),
                  Expanded(
                    child: _buildMiniStat(
                      label: 'Remaining',
                      value: CurrencyFormatter.format(parentRemaining),
                      color: parentRemaining < 0 ? AppColors.expense : AppColors.income,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.textMuted),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
