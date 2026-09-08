import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/data/dtos/order_dto.dart';
import '../../core/providers/orders_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/tables_provider.dart';

// ── Screen Class ──────────────────────────────────────────────────────────────
class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  String _searchQuery = '';
  OrderDto? _selectedOrder;
  bool _filterToday = true;
  String _filterTable = 'All';
  String _filterStatus =
      'All'; // 'All', 'Completed', 'Voided', 'Pending/Preparing'

  // Controller for Search Input
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersProvider.notifier).loadOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final tablesState = ref.watch(tablesProvider);
    final desktop = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Order History & KOT Logs',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: AppTheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: 22.r),
            onPressed: () => ref.read(ordersProvider.notifier).loadOrders(forceRefresh: true),
          ),
          SizedBox(width: 8.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Divider(
            height: 1.h,
            thickness: 1.h,
            color: AppTheme.surfaceContainerHigh,
          ),
        ),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (ordersState.error != null) {
              return Center(
                child: Text(
                  'Error loading orders: ${ordersState.error}',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.error),
                ),
              );
            }
            if (ordersState.isLoading && ordersState.ordersById.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }
            final allOrders = ordersState.ordersById.values.map((dto) {
              return dto.copyWith(tableLabel: tablesState.tablesById[dto.tableId]?.label);
            }).toList();
            // Apply filtering logic
            final filteredOrders = allOrders.where((order) {
              // 1. Search Query
              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                final orderId = order.id.toLowerCase();
                final tableLabel = order.tableLabel.toLowerCase();
                final staffName = (order.staffName ?? '').toLowerCase();
                if (!orderId.contains(query) &&
                    !tableLabel.contains(query) &&
                    !staffName.contains(query)) {
                  return false;
                }
              }

              // 2. Status Filter
              if (_filterStatus != 'All') {
                if (_filterStatus == 'Completed' &&
                    order.status != OrderStatus.served) {
                  return false;
                }
                if (_filterStatus == 'Voided' &&
                    order.status != OrderStatus.cancelled) {
                  return false;
                }
                if (_filterStatus == 'Pending/Preparing' &&
                    order.status != OrderStatus.pending &&
                    order.status != OrderStatus.preparing &&
                    order.status != OrderStatus.ready) {
                  return false;
                }
              }

              // 3. Table Filter
              if (_filterTable != 'All') {
                if (order.tableLabel != _filterTable) {
                  return false;
                }
              }

              // 4. Date/Today Filter
              if (_filterToday) {
                final now = DateTime.now();
                final localCreated = order.createdAt.toLocal();
                if (localCreated.year != now.year ||
                    localCreated.month != now.month ||
                    localCreated.day != now.day) {
                  return false;
                }
              }

              return true;
            }).toList();

            // Set default selected order if null or not in the filtered list
            if (filteredOrders.isNotEmpty) {
              if (_selectedOrder == null ||
                  !filteredOrders.any((o) => o.id == _selectedOrder!.id)) {
                _selectedOrder = filteredOrders.first;
              }
            } else {
              _selectedOrder = null;
            }

            if (desktop) {
              // ── Responsive Desktop/Tablet Layout (Split Pane 1/3 and 2/3) ──
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side: Filters + Historical List (1/3 width)
                  Container(
                    width: 320.w,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      border: Border(
                        right: BorderSide(
                          color: AppTheme.surfaceContainerHigh,
                          width: 1.w,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSearchAndFilters(context),
                        Divider(
                          height: 1.h,
                          thickness: 1.h,
                          color: AppTheme.surfaceContainerHigh,
                        ),
                        Expanded(child: _buildOrdersList(filteredOrders, true, allOrders.isEmpty)),
                      ],
                    ),
                  ),

                  // Right Side: Detailed View (2/3 width)
                  Expanded(
                    child: Container(
                      color: AppTheme.background,
                      child: _selectedOrder != null
                          ? _buildDetailedOrderPanel(context, _selectedOrder!)
                          : _buildEmptyStateDetailsPanel(),
                    ),
                  ),
                ],
              );
            } else {
              // ── Mobile Layout ──
              return Column(
                children: [
                  _buildSearchAndFilters(context),
                  Divider(
                    height: 1.h,
                    thickness: 1.h,
                    color: AppTheme.surfaceContainerHigh,
                  ),
                  Expanded(child: _buildOrdersList(filteredOrders, false, allOrders.isEmpty)),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  // ── Search and Filters Header Block ─────────────────────────────────────────
  Widget _buildSearchAndFilters(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Box
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: AppTheme.surfaceContainerHigh,
                width: 1.w,
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: AppTheme.secondary,
                  size: 20.r,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      color: AppTheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search ID, Table, Waiter...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: AppTheme.secondary,
                        fontSize: 13.sp,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    child: Icon(
                      Icons.close_rounded,
                      color: AppTheme.secondary,
                      size: 16.r,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // 2. Filters Heading Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: AppTheme.titleSm.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.sp,
                ),
              ),
              InkWell(
                onTap: () => _showFilterDialog(context),
                borderRadius: BorderRadius.circular(8.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        color: AppTheme.secondary,
                        size: 14.r,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Filter',
                        style: AppTheme.labelSm.copyWith(
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // 3. Active Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Today filter
                if (_filterToday)
                  _buildActiveChip(
                    'Today',
                    true,
                    () => setState(() => _filterToday = false),
                  ),
                // Table filter
                if (_filterTable != 'All')
                  _buildActiveChip(
                    'Table: $_filterTable',
                    false,
                    () => setState(() => _filterTable = 'All'),
                  ),
                // Status filter
                if (_filterStatus != 'All')
                  _buildActiveChip(
                    'Status: $_filterStatus',
                    false,
                    () => setState(() => _filterStatus = 'All'),
                  ),
                if (!_filterToday &&
                    _filterTable == 'All' &&
                    _filterStatus == 'All')
                  Text(
                    'No active filters',
                    style: AppTheme.bodySm.copyWith(
                      color: AppTheme.secondary.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChip(String label, bool primary, VoidCallback onClear) {
    return Container(
      margin: EdgeInsets.only(right: 6.w),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: primary
            ? AppTheme.primaryContainer
            : AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTheme.labelSm.copyWith(
              color: primary ? Colors.white : AppTheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 10.sp,
            ),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: onClear,
            child: Icon(
              Icons.close_rounded,
              size: 12.r,
              color: primary ? Colors.white70 : AppTheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Orders List Stream Builder ──────────────────────────────────────────────
  Widget _buildOrdersList(List<OrderDto> orders, bool isDesktop, bool hasNoDataAtAll) {
    if (hasNoDataAtAll) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_rounded,
                size: 48.r,
                color: AppTheme.secondary.withValues(alpha: 0.3),
              ),
              SizedBox(height: 12.h),
              Text(
                'No orders yet',
                style: AppTheme.titleSm.copyWith(color: AppTheme.secondary),
              ),
              SizedBox(height: 4.h),
              Text(
                'Orders from the POS or QR will appear here.',
                textAlign: TextAlign.center,
                style: AppTheme.bodySm.copyWith(
                  color: AppTheme.secondary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 48.r,
                color: AppTheme.secondary.withValues(alpha: 0.3),
              ),
              SizedBox(height: 12.h),
              Text(
                'No matching orders',
                style: AppTheme.titleSm.copyWith(color: AppTheme.secondary),
              ),
              SizedBox(height: 4.h),
              Text(
                'Try clearing your search query or active filter chips.',
                textAlign: TextAlign.center,
                style: AppTheme.bodySm.copyWith(
                  color: AppTheme.secondary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemBuilder: (context, index) {
        final order = orders[index];
        final isSelected = _selectedOrder?.id == order.id;

        return _buildOrderCard(order, isSelected, isDesktop)
            .animate(delay: Duration(milliseconds: 30 * index))
            .fadeIn(duration: 350.ms)
            .slideY(begin: 0.05, end: 0, duration: 350.ms);
      },
    );
  }

  // ── High Fidelity Order Card Widget ─────────────────────────────────────────
  Widget _buildOrderCard(OrderDto order, bool isSelected, bool isDesktop) {
    final orderId = order.id.length >= 8
        ? order.id.substring(order.id.length - 8).toUpperCase()
        : order.id.toUpperCase();
    final tableLabel = order.tableLabel;
    final waiterName = order.staffName ?? (order.staffId == null ? 'Self-Order' : 'Unknown Staff'); // Default mock fallback
    final amount = (order.totalAmount / 100).toStringAsFixed(2);
    final displayTime = order.displayTime;

    final isVoided = order.status == OrderStatus.cancelled;
    final isCompleted = order.status == OrderStatus.served;

    // Determine status text & colors to match tailwind style
    Color statusBgColor = AppTheme.surfaceContainerHigh;
    Color statusTextColor = AppTheme.secondary;
    String statusText = 'Completed';

    if (isVoided) {
      statusBgColor = AppTheme.errorContainer;
      statusTextColor = AppTheme.error;
      statusText = 'Voided';
    } else if (order.status == OrderStatus.preparing) {
      statusBgColor = Colors.orange.shade50;
      statusTextColor = Colors.orange.shade800;
      statusText = 'Cooking';
    } else if (order.status == OrderStatus.ready) {
      statusBgColor = AppColors.success.withValues(alpha: 0.1);
      statusTextColor = AppColors.success;
      statusText = 'Ready';
    } else if (order.status == OrderStatus.pending) {
      statusBgColor = AppTheme.primaryFixed;
      statusTextColor = AppTheme.primary;
      statusText = 'Pending';
    } else if (isCompleted) {
      statusBgColor = AppTheme.surfaceContainerHighest;
      statusTextColor = AppTheme.onSurface;
      statusText = 'Completed';
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOrder = order;
        });
        if (!isDesktop) {
          // In mobile, slide open a details bottom sheet panel that looks full-screen
          _showMobileDetailsSheet(context, order);
        }
      },
      child: Opacity(
        opacity: isVoided ? 0.8 : 1.0,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primary
                  : isVoided
                  ? AppTheme.surfaceContainerHigh
                  : AppTheme.surfaceContainerHighest,
              width: isSelected ? 1.5.w : 1.w,
            ),
            boxShadow: isSelected
                ? AppTheme.crimsonShadow
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#ORD-$orderId',
                          style: AppTheme.headlineMd.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            decoration: isVoided
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: AppTheme.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Table $tableLabel',
                          style: AppTheme.bodySm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      statusText,
                      style: AppTheme.labelSm.copyWith(
                        color: statusTextColor,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Info and total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Waiter row
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 13.r,
                              color: AppTheme.secondary,
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                waiterName,
                                style: AppTheme.bodySm.copyWith(
                                  color: AppTheme.secondary,
                                  fontSize: 11.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        // Time row
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 13.r,
                              color: AppTheme.secondary,
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                displayTime,
                                style: AppTheme.bodySm.copyWith(
                                  color: AppTheme.secondary,
                                  fontSize: 11.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '₹$amount',
                    style: AppTheme.titleLg.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 15.sp,
                      color: AppTheme.onSurface,
                      decoration: isVoided
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── High Fidelity Desktop Detailed Order Panel (Right Side) ─────────────────
  Widget _buildDetailedOrderPanel(BuildContext context, OrderDto order) {
    final orderId = order.id.length >= 8
        ? order.id.substring(order.id.length - 8).toUpperCase()
        : order.id.toUpperCase();
    final waiterName = order.staffName ?? (order.staffId == null ? 'Self-Order' : 'Unknown Staff');
    final totalAmount = (order.totalAmount / 100).toStringAsFixed(2);

    final isVoided = order.status == OrderStatus.cancelled;

    return Column(
      children: [
        // 1. Detailed Header Card
        Container(
          color: AppTheme.surfaceContainerLowest,
          padding: EdgeInsets.all(24.r),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#ORD-$orderId Detail',
                      style: AppTheme.headlineLg.copyWith(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      order.staffId == null
                          ? order.tableLabel
                          : '${order.tableLabel} • Waiter: $waiterName',
                      style: AppTheme.bodyMd.copyWith(
                        color: AppTheme.secondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹$totalAmount',
                    style: AppTheme.displayLg.copyWith(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: isVoided
                          ? AppTheme.errorContainer
                          : AppTheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      isVoided ? 'Voided' : 'Completed',
                      style: AppTheme.labelSm.copyWith(
                        color: isVoided ? AppTheme.error : AppTheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(
          height: 1.h,
          thickness: 1.h,
          color: AppTheme.surfaceContainerHigh,
        ),

        // 2. Main Content (Item Breakdown + Stepper KOT Logs)
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.r),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Items Breakdown List (3/5 Width)
                Expanded(flex: 3, child: _buildItemsBreakdownCard(order)),
                SizedBox(width: 20.w),

                // KDS Stepper Audit Logs (2/5 Width)
                Expanded(flex: 2, child: _buildKotLogsCard(order)),
              ],
            ),
          ),
        ),

        // 3. Action Footer
        Divider(
          height: 1.h,
          thickness: 1.h,
          color: AppTheme.surfaceContainerHigh,
        ),
        _buildActionFooter(context, order),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  // ── Items Breakdown Widget Card ─────────────────────────────────────────────
  Widget _buildItemsBreakdownCard(OrderDto order) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items',
            style: AppTheme.titleLg.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 6.h),
          Divider(color: AppTheme.surfaceContainerHigh),
          SizedBox(height: 12.h),
          if (order.items.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Text(
                  'No items in this order.',
                  style: AppTheme.bodyMd.copyWith(color: AppTheme.secondary),
                ),
              ),
            ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (context, index) => Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Divider(height: 1.h, color: AppTheme.surfaceContainerLow),
            ),
            itemBuilder: (context, index) {
              final item = order.items[index];
              final linePrice = (item.lineTotalAmount / 100).toStringAsFixed(2);

              // Extract custom instructions if any
              final List<String> customizations = [];
              if (item.notes != null && item.notes!.isNotEmpty) {
                // Split custom instructions by comma or newlines
                customizations.addAll(item.notes!.split(RegExp(r'[,\n]')));
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.quantity}x ${item.menuItemName}',
                          style: AppTheme.bodyMd.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.sp,
                          ),
                        ),
                        if (customizations.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          ...customizations.map(
                            (note) => Container(
                              margin: EdgeInsets.only(bottom: 2.h),
                              padding: EdgeInsets.only(left: 8.w),
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: AppTheme.outlineVariant,
                                    width: 2.w,
                                  ),
                                ),
                              ),
                              child: Text(
                                note.trim(),
                                style: AppTheme.bodySm.copyWith(
                                  color: AppTheme.secondary,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    '₹$linePrice',
                    style: AppTheme.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Stepper KOT Logs Card Widget ────────────────────────────────────────────
  Widget _buildKotLogsCard(OrderDto order) {
    // We will generate realistic stepper timestamps based on createdAt
    final dt = order.createdAt.toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');

    // Mismatches or events
    final time1 = '${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)}';

    final serveTime = order.updatedAt.toLocal();
    final time3 =
        '${pad(serveTime.hour)}:${pad(serveTime.minute)}:${pad(serveTime.second)}';

    final isVoided = order.status == OrderStatus.cancelled;
    final isServed = order.status == OrderStatus.served;


    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 18.r,
                color: AppTheme.primary,
              ),
              SizedBox(width: 8.w),
              Text(
                'KOT Logs',
                style: AppTheme.titleLg.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Stepper Body
          _buildStepRow(
            time: time1,
            title: 'Order Fired',
            subtitle: 'POS Terminal 1',
            isLatest: !isServed && !isVoided,
            isCompleted: true,
          ),
          _buildStepLine(isServed || isVoided),
          if (isVoided)
            _buildStepRow(
              time: time3,
              title: 'Order Cancelled',
              subtitle: 'Manager Console Override',
              isLatest: true,
              isCompleted: true,
              isError: true,
            )
          else
            _buildStepRow(
              time: time3,
              title: 'Order Fulfilled',
              subtitle: 'Expo Station KDS',
              isLatest: isServed,
              isCompleted: isServed,
            ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String time,
    required String title,
    required String subtitle,
    required bool isLatest,
    required bool isCompleted,
    bool isError = false,
  }) {
    Color dotColor = AppTheme.surfaceContainerHigh;
    if (isCompleted) {
      dotColor = isError
          ? AppTheme.error
          : isLatest
          ? AppTheme.primary
          : AppTheme.secondary;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time Stamp
        SizedBox(
          width: 60.w,
          child: Text(
            time,
            style: AppTheme.bodySm.copyWith(
              color: AppTheme.secondary,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Indicator Dot
        Container(
          margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
          width: 10.r,
          height: 10.r,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            border: isLatest
                ? Border.all(color: Colors.white, width: 2.w)
                : null,
            boxShadow: isLatest
                ? [
                    BoxShadow(
                      color: dotColor.withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        ),

        // Text Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyMd.copyWith(
                  fontWeight: isLatest ? FontWeight.w800 : FontWeight.w700,
                  fontSize: 12.sp,
                  color: isLatest
                      ? isError
                            ? AppTheme.error
                            : AppTheme.primary
                      : AppTheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: AppTheme.bodySm.copyWith(
                  color: AppTheme.secondary,
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool active) {
    return Container(
      margin: EdgeInsets.only(left: 74.w),
      width: 2.w,
      height: 24.h,
      color: active ? AppTheme.surfaceContainerHigh : AppTheme.surfaceContainer,
    );
  }

  // ── Action Footer Buttons ───────────────────────────────────────────────────
  Widget _buildActionFooter(BuildContext context, OrderDto order) {
    final isVoided = order.status == OrderStatus.cancelled;

    return Container(
      color: AppTheme.surfaceContainerLowest,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Void / Refund Button
          OutlinedButton.icon(
            onPressed: isVoided
                ? null
                : () => _triggerVoidRefund(context, ref, order),
            icon: Icon(
              Icons.lock_outline_rounded,
              size: 16.r,
              color: isVoided ? AppTheme.surfaceDim : AppTheme.primary,
            ),
            label: Text(
              'Void / Refund',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 12.sp,
                color: isVoided ? AppTheme.surfaceDim : AppTheme.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isVoided ? AppTheme.surfaceContainer : AppTheme.primary,
                width: 1.w,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              minimumSize: Size(130.w, 40.h),
            ),
          ),
          SizedBox(width: 12.w),

          // Re-Print KOT Button
          ElevatedButton.icon(
            onPressed: () => _triggerKotRePrint(context, order),
            icon: Icon(Icons.print_rounded, size: 16.r, color: Colors.white),
            label: Text(
              'Re-Print KOT',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 12.sp,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryContainer,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              minimumSize: Size(130.w, 40.h),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions Triggers ────────────────────────────────────────────────────────
  void _triggerKotRePrint(BuildContext context, OrderDto order) {
    final orderId = order.id.length >= 8
        ? order.id.substring(order.id.length - 8).toUpperCase()
        : order.id.toUpperCase();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.print_rounded, color: Colors.white),
            SizedBox(width: 8.w),
            Text('Re-sending KOT #ORD-$orderId to Local Thermal Printer...'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey.shade900,
      ),
    );
  }

  void _triggerVoidRefund(BuildContext context, WidgetRef ref, OrderDto order) {
    // Show confirmation Dialog
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLowest,
          title: Text(
            'Void Order Confirmation',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
          content: Text(
            'Are you sure you want to VOID and refund order #ORD-${order.id.length >= 8 ? order.id.substring(order.id.length - 8).toUpperCase() : order.id}? This requires manager approval.',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.secondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.secondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Perform state cancellation via notifier or provider
                ref
                    .read(ordersProvider.notifier)
                    .transitionOrderStatus(order.id, OrderStatus.cancelled);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order has been Voided & Refund triggered.'),
                    backgroundColor: AppTheme.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                // Also pop detail dialog in mobile
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              child: Text(
                'Void Order',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Mobile Screen Overlay Panel ─────────────────────────────────────────────
  void _showMobileDetailsSheet(BuildContext context, OrderDto order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                child: Column(
                  children: [
                    // Pull Handle Indicator
                    Container(
                      margin: EdgeInsets.only(top: 8.h, bottom: 8.h),
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),

                    // Detailed Content Wrapper
                    Expanded(
                      child: SingleChildScrollView(
                        controller: controller,
                        child: Column(
                          children: [
                            // Header Profile
                            _buildMobileHeaderPanel(context, order),
                            Divider(
                              height: 1.h,
                              color: AppTheme.surfaceContainerHigh,
                            ),

                            // Items + Logs list
                            Padding(
                              padding: EdgeInsets.all(16.r),
                              child: Column(
                                children: [
                                  _buildItemsBreakdownCard(order),
                                  SizedBox(height: 16.h),
                                  _buildKotLogsCard(order),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Action Footer fixed at bottom of sheet
                    Divider(height: 1.h, color: AppTheme.surfaceContainerHigh),
                    _buildActionFooter(context, order),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMobileHeaderPanel(BuildContext context, OrderDto order) {
    final orderId = order.id.length >= 8
        ? order.id.substring(order.id.length - 8).toUpperCase()
        : order.id.toUpperCase();
    final waiterName = order.staffName ?? (order.staffId == null ? 'Self-Order' : 'Unknown Staff');
    final totalAmount = (order.totalAmount / 100).toStringAsFixed(2);
    final isVoided = order.status == OrderStatus.cancelled;

    return Container(
      color: AppTheme.surfaceContainerLowest,
      padding: EdgeInsets.all(20.r),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#ORD-$orderId Detail',
                  style: AppTheme.titleLg.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2.h),
                Text(
                  order.staffId == null
                      ? order.tableLabel
                      : '${order.tableLabel} • Waiter: $waiterName',
                  style: AppTheme.bodySm.copyWith(color: AppTheme.secondary),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹$totalAmount',
                style: AppTheme.headlineMd.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                ),
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isVoided
                      ? AppTheme.errorContainer
                      : AppTheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  isVoided ? 'Voided' : 'Completed',
                  style: AppTheme.labelSm.copyWith(
                    color: isVoided ? AppTheme.error : AppTheme.onSurface,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Desktop Empty State Details View ────────────────────────────────────────
  Widget _buildEmptyStateDetailsPanel() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_rounded,
            size: 64.r,
            color: AppTheme.surfaceContainerHigh,
          ),
          SizedBox(height: 12.h),
          Text(
            'No Order Selected',
            style: AppTheme.titleLg.copyWith(
              color: AppTheme.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Select an order from the list to view items breakdown & KOT logs.',
            style: AppTheme.bodySm.copyWith(
              color: AppTheme.secondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ── Show Filter Dialog ──────────────────────────────────────────────────────
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        String tempStatus = _filterStatus;
        String tempTable = _filterTable;
        bool tempToday = _filterToday;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceContainerLowest,
              title: Text(
                'Filter Order History',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today toggle
                  SwitchListTile(
                    title: Text(
                      'Today Only',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    value: tempToday,
                    activeThumbColor: AppTheme.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setDialogState(() {
                        tempToday = val;
                      });
                    },
                  ),
                  SizedBox(height: 12.h),

                  // Status Select
                  Text(
                    'Order Status',
                    style: AppTheme.labelSm.copyWith(color: AppTheme.secondary),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: DropdownButton<String>(
                      value: tempStatus,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: ['All', 'Completed', 'Voided', 'Pending/Preparing']
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            tempStatus = val;
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Table Select
                  Text(
                    'Table',
                    style: AppTheme.labelSm.copyWith(color: AppTheme.secondary),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: DropdownButton<String>(
                      value: tempTable,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: ['All', '1', '2', '3', '4', '8', '12']
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s == 'All' ? 'All Tables' : 'Table $s',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            tempTable = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Reset to defaults
                    setDialogState(() {
                      tempStatus = 'All';
                      tempTable = 'All';
                      tempToday = true;
                    });
                  },
                  child: Text(
                    'Reset',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.secondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filterStatus = tempStatus;
                      _filterTable = tempTable;
                      _filterToday = tempToday;
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryContainer,
                  ),
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
