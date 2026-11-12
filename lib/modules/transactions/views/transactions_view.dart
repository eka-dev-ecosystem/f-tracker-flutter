import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/category_icon_helper.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/offline_sync_banner.dart';
import '../../../routes/app_routes.dart';
import '../../navigation/controllers/navigation_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../controllers/transaction_controller.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';
import 'widgets/transaction_card.dart';
import 'widgets/transaction_calendar_widget.dart';

class TransactionsView extends StatelessWidget {
  const TransactionsView({super.key});

  TransactionController get controller {
    if (!Get.isRegistered<TransactionController>()) {
      if (!Get.isRegistered<TransactionRepository>()) {
        Get.lazyPut<TransactionRepository>(
          () => TransactionRepository(apiClient: Get.find<ApiClient>()),
          fenix: true,
        );
      }
      return Get.put(
        TransactionController(
          repository: Get.find<TransactionRepository>(),
          storageService: Get.find<StorageService>(),
        ),
      );
    }
    return Get.find<TransactionController>();
  }

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.canPop(context),
        title: const Text('Transactions'),
        backgroundColor: AppColors.surface,
        actions: [
          // View Mode Switcher (List vs Calendar)
          Obx(() => IconButton(
            icon: Icon(
              controller.displayMode.value == TransactionDisplayMode.list
                  ? Icons.calendar_month_rounded
                  : Icons.view_list_rounded,
              color: controller.displayMode.value == TransactionDisplayMode.calendar
                  ? AppColors.primary
                  : AppColors.textPrimary,
            ),
            tooltip: controller.displayMode.value == TransactionDisplayMode.list
                ? 'Calendar View'
                : 'List View',
            onPressed: controller.toggleDisplayMode,
          )),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh data',
            onPressed: () => controller.fetchTransactions(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: Get.isRegistered<NavigationController>()
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              tooltip: 'Record New Transaction',
              onPressed: () => Get.toNamed(Routes.addTransaction),
              child: const Icon(Icons.add_rounded, size: 28),
            ),
      body: Column(
        children: [
          // Offline & Sync Status Banner
          const OfflineSyncBanner(),

          // Body View (List or Calendar)
          Expanded(
            child: Obx(() {
              if (controller.displayMode.value == TransactionDisplayMode.calendar) {
                return _buildCalendarView(context);
              }
              return _buildListView(context);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => controller.fetchTransactions(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Calendar Month Grid Widget
            Obx(() => TransactionCalendarWidget(
              focusedMonth: controller.calendarFocusedMonth.value,
              selectedDate: controller.calendarSelectedDate.value,
              dailySummaries: controller.calendarDailySummaries,
              onSelectDate: controller.onCalendarDaySelected,
              onPrevMonth: controller.prevCalendarMonth,
              onNextMonth: controller.nextCalendarMonth,
              onToday: controller.resetCalendarToToday,
            )),
            const SizedBox(height: 18),

            // Selected Date Breakdown Header & Summary
            Obx(() {
              final sel = controller.calendarSelectedDate.value;
              final key = '${sel.year.toString().padLeft(4, '0')}-${sel.month.toString().padLeft(2, '0')}-${sel.day.toString().padLeft(2, '0')}';
              final dailyTxs = controller.selectedDayTransactions;
              return _buildDailySectionHeader(key, dailyTxs);
            }),
            const SizedBox(height: 10),

            // Daily Transactions List
            Obx(() {
              final dailyTxs = controller.selectedDayTransactions;

              if (dailyTxs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.event_note_rounded,
                          size: 26,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No transactions on this date',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap below to record an income or expense',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Get.toNamed(Routes.addTransaction),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text(
                          'Record Transaction',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: dailyTxs.map((tx) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TransactionCard(
                    transaction: tx,
                    onDelete: () => controller.deleteTransaction(tx),
                  ),
                )).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context) {
    return Column(
      children: [
        // Search & Filter Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: AppColors.surface,
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: controller.searchController,
                onChanged: controller.onSearchChanged,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            controller.searchController.clear();
                            controller.onSearchChanged('');
                          },
                        )
                      : const SizedBox.shrink()),
                ),
              ),
              const SizedBox(height: 10),

              // Period View Pills
              SizedBox(
                height: 34,
                child: Obx(() => ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final period in ['Day', 'Week', 'Month', 'Year', 'All'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildViewChip(period, controller.selectedView.value == period),
                      ),
                    // Custom Month/Year picker button
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildCustomDateChip(context),
                    ),
                  ],
                )),
              ),
              const SizedBox(height: 10),

              // Custom date indicator banner
              Obx(() {
                if (controller.filterYear.value == null) {
                  return const SizedBox.shrink();
                }
                final year = controller.filterYear.value!;
                final month = controller.filterMonth.value;
                final label = month != null
                    ? '${_monthNames[month - 1]} $year'
                    : 'Year $year';
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt_rounded, size: 16, color: AppColors.primary.withValues(alpha: 0.8)),
                      const SizedBox(width: 8),
                      Text(
                        'Filtered: $label',
                        style: TextStyle(
                          color: AppColors.primary.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: controller.clearCustomFilter,
                        child: Icon(Icons.close_rounded, size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                );
              }),

              // Category active indicator banner
              Obx(() {
                if (controller.selectedCategory.value.isEmpty ||
                    controller.selectedCategory.value == 'all') {
                  return const SizedBox.shrink();
                }
                final catName = controller.selectedCategoryName.value.isNotEmpty
                    ? controller.selectedCategoryName.value
                    : 'Selected Category';
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.category_rounded, size: 16, color: AppColors.primary.withValues(alpha: 0.8)),
                      const SizedBox(width: 8),
                      Text(
                        'Category: $catName',
                        style: TextStyle(
                          color: AppColors.primary.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: controller.clearCategoryFilter,
                        child: Icon(Icons.close_rounded, size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                );
              }),

              // Type Filter Pills
              Obx(() => Row(
                children: [
                  _buildFilterChip('All', ''),
                  const SizedBox(width: 8),
                  _buildFilterChip('Expense', 'Expense'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Income', 'Income'),
                ],
              )),
              const SizedBox(height: 10),

              // Category & Sort Toolbar Row
              Row(
                children: [
                  // Category Filter Button
                  Expanded(
                    child: _buildCategoryDropdownButton(context),
                  ),
                  const SizedBox(width: 10),
                  // Sort Filter Button
                  Expanded(
                    child: _buildSortDropdownButton(context),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Total Overview Strip
        Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${controller.filterTotalCount.value > 0 ? controller.filterTotalCount.value : controller.transactions.length} Transactions',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              Row(
                children: [
                  Text(
                    '+${CurrencyFormatter.formatCompact(controller.incomeTotal.value)}',
                    style: const TextStyle(color: AppColors.income, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '-${CurrencyFormatter.formatCompact(controller.expenseTotal.value)}',
                    style: const TextStyle(color: AppColors.expense, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        )),

        // Transactions List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => controller.fetchTransactions(),
            color: AppColors.primary,
            child: Obx(() {
              if (controller.isLoading.value && controller.transactions.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (controller.transactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 54, color: AppColors.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 14),
                      const Text(
                        'No transactions yet',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap the + button to record a transaction',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              final grouped = controller.groupedTransactions;
              final dateKeys = grouped.keys.toList();

              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                itemCount: dateKeys.length + (controller.isLoadingMore.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == dateKeys.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      ),
                    );
                  }

                  final dateKey = dateKeys[index];
                  final dailyTxs = grouped[dateKey] ?? [];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDailySectionHeader(dateKey, dailyTxs),
                        ...dailyTxs.map((tx) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TransactionCard(
                                transaction: tx,
                                onDelete: () => controller.deleteTransaction(tx),
                              ),
                            )),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDailySectionHeader(String dateKey, List<TransactionModel> dailyTxs) {
    final summary = controller.getDailySummary(dailyTxs);
    final net = summary['net'] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4, left: 2, right: 2),
      child: Row(
        children: [
          // Blue Accent Bar
          Container(
            width: 3.5,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          // Date title
          Text(
            _formatDateHeading(dateKey),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 6),
          // Count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${dailyTxs.length}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          // Daily Summary Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: (net >= 0 ? AppColors.income : AppColors.expense).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (net >= 0 ? AppColors.income : AppColors.expense).withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Net: ',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${net >= 0 ? "+" : "-"}${CurrencyFormatter.format(net.abs())}',
                  style: TextStyle(
                    color: net >= 0 ? AppColors.income : AppColors.expense,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateHeading(String dateKey) {
    try {
      final parts = dateKey.split('-').map(int.parse).toList();
      if (parts.length == 3) {
        final date = DateTime(parts[0], parts[1], parts[2]);
        final storage = Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;
        final userTz = storage?.user?['timezone']?.toString();
        final now = CurrencyFormatter.nowInTimezone(userTz);
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));

        if (date == today) {
          return 'Today';
        } else if (date == yesterday) {
          return 'Yesterday';
        } else {
          return CurrencyFormatter.formatDisplayDate(date);
        }
      }
    } catch (_) {}
    return dateKey;
  }

  Widget _buildViewChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => controller.setViewPeriod(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDateChip(BuildContext context) {
    return Obx(() {
      final isActive = controller.filterYear.value != null;
      return GestureDetector(
        onTap: () => _showMonthYearPicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: isActive ? null : Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.date_range_rounded,
                size: 14,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Custom',
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showMonthYearPicker(BuildContext context) {
    final now = DateTime.now();
    final pickerYear = (controller.filterYear.value ?? now.year).obs;
    final pickerMonth = RxnInt(controller.filterMonth.value);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
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
                  'Filter by Month & Year',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Year Picker Row
            Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
                  onPressed: () => pickerYear.value--,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${pickerYear.value}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onPressed: () {
                    if (pickerYear.value < now.year + 1) pickerYear.value++;
                  },
                ),
              ],
            )),
            const SizedBox(height: 16),

            // Month Grid
            Obx(() => GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: List.generate(12, (i) {
                final m = i + 1;
                final isSelected = pickerMonth.value == m;
                final isFuture = pickerYear.value == now.year && m > now.month;
                return GestureDetector(
                  onTap: isFuture ? null : () {
                    if (pickerMonth.value == m) {
                      pickerMonth.value = null; // Deselect for year-only filter
                    } else {
                      pickerMonth.value = m;
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : isFuture
                              ? AppColors.surfaceVariant.withValues(alpha: 0.3)
                              : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: AppColors.primary)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _monthNames[i].substring(0, 3),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isFuture
                                ? AppColors.textMuted.withValues(alpha: 0.4)
                                : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
            )),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Get.back();
                      controller.clearCustomFilter();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Reset', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      Get.back();
                      if (pickerMonth.value != null) {
                        controller.setCustomMonthYear(pickerYear.value, pickerMonth.value!);
                      } else {
                        controller.setCustomYear(pickerYear.value);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Obx(() {
                      final month = pickerMonth.value;
                      final label = month != null
                          ? 'Show ${_monthNames[month - 1]} ${pickerYear.value}'
                          : 'Show Year ${pickerYear.value}';
                      return Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = controller.selectedType.value == type;
    return GestureDetector(
      onTap: () => controller.setFilterType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdownButton(BuildContext context) {
    return Obx(() {
      final isFiltered = controller.selectedCategory.value.isNotEmpty &&
          controller.selectedCategory.value != 'all';
      final categoryName = controller.selectedCategoryName.value.isNotEmpty
          ? controller.selectedCategoryName.value
          : 'All Categories';

      return GestureDetector(
        onTap: () => _showCategoryFilterSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isFiltered
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceVariant.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFiltered
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.category_rounded,
                size: 16,
                color: isFiltered ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isFiltered ? AppColors.primaryLight : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isFiltered ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: isFiltered ? AppColors.primary : AppColors.textMuted,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSortDropdownButton(BuildContext context) {
    return Obx(() {
      final sort = controller.selectedSort.value;
      final isNonDefault = sort != 'newest';

      String sortLabel;
      IconData sortIcon;
      switch (sort) {
        case 'oldest':
          sortLabel = 'Oldest First';
          sortIcon = Icons.history_rounded;
          break;
        case 'highest':
          sortLabel = 'Highest Amount';
          sortIcon = Icons.trending_up_rounded;
          break;
        case 'lowest':
          sortLabel = 'Lowest Amount';
          sortIcon = Icons.trending_down_rounded;
          break;
        case 'newest':
        default:
          sortLabel = 'Newest First';
          sortIcon = Icons.schedule_rounded;
          break;
      }

      return GestureDetector(
        onTap: () => _showSortSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isNonDefault
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceVariant.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isNonDefault
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                sortIcon,
                size: 16,
                color: isNonDefault ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  sortLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isNonDefault ? AppColors.primaryLight : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isNonDefault ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: isNonDefault ? AppColors.primary : AppColors.textMuted,
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showCategoryFilterSheet(BuildContext context) {
    AppHaptics.light();
    final categories = controller.availableCategories;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter by Category',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Obx(() {
                  if (controller.selectedCategory.value.isEmpty ||
                      controller.selectedCategory.value == 'all') {
                    return const SizedBox.shrink();
                  }
                  return TextButton(
                    onPressed: () {
                      controller.clearCategoryFilter();
                      Get.back();
                    },
                    child: const Text('Reset', style: TextStyle(color: AppColors.primary)),
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Option: All Categories
                  Obx(() {
                    final isAll = controller.selectedCategory.value.isEmpty ||
                        controller.selectedCategory.value == 'all';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isAll
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.grid_view_rounded,
                          size: 18,
                          color: isAll ? AppColors.primary : AppColors.textMuted,
                        ),
                      ),
                      title: Text(
                        'All Categories',
                        style: TextStyle(
                          color: isAll ? AppColors.primaryLight : AppColors.textPrimary,
                          fontWeight: isAll ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      trailing: isAll
                          ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 20)
                          : null,
                      onTap: () {
                        controller.clearCategoryFilter();
                        Get.back();
                      },
                    );
                  }),
                  const Divider(color: AppColors.border, height: 16),
                  // Categories list
                  for (final cat in categories)
                    Obx(() {
                      final isSelected = controller.selectedCategory.value == cat.id;
                      final catColor = _parseColor(cat.color);
                      final iconData = CategoryIconHelper.getIconData(cat.icon, cat.name);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(iconData, size: 18, color: catColor),
                        ),
                        title: Text(
                          cat.name,
                          style: TextStyle(
                            color: isSelected ? AppColors.primaryLight : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          cat.type.isNotEmpty
                              ? cat.type[0].toUpperCase() + cat.type.substring(1)
                              : 'General',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 20)
                            : null,
                        onTap: () {
                          controller.setCategoryFilter(cat.id, cat.name);
                          Get.back();
                        },
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showSortSheet(BuildContext context) {
    AppHaptics.light();
    final sortOptions = [
      {'key': 'newest', 'label': 'Newest First', 'icon': Icons.schedule_rounded, 'desc': 'Recent transactions first'},
      {'key': 'oldest', 'label': 'Oldest First', 'icon': Icons.history_rounded, 'desc': 'Earliest transactions first'},
      {'key': 'highest', 'label': 'Highest Amount', 'icon': Icons.trending_up_rounded, 'desc': 'Largest transactions first'},
      {'key': 'lowest', 'label': 'Lowest Amount', 'icon': Icons.trending_down_rounded, 'desc': 'Smallest transactions first'},
    ];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Sort Transactions',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            for (final opt in sortOptions)
              Obx(() {
                final isSelected = controller.selectedSort.value == opt['key'];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      opt['icon'] as IconData,
                      size: 18,
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                  title: Text(
                    opt['label'] as String,
                    style: TextStyle(
                      color: isSelected ? AppColors.primaryLight : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    opt['desc'] as String,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 20)
                      : null,
                  onTap: () {
                    controller.setSort(opt['key'] as String);
                    Get.back();
                  },
                );
              }),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.primary;
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}
