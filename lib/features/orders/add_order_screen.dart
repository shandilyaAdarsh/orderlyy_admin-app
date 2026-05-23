import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/data/dtos/menu_dto.dart';
import '../../core/data/dtos/order_dto.dart';
import '../../core/providers/menu_providers.dart';
import '../../core/providers/orders_providers.dart';
import '../../core/theme/app_theme.dart';

class AddOrderScreen extends ConsumerStatefulWidget {
  final String tableId;
  final String tableLabel;
  final OrderDto? existingOrder;

  const AddOrderScreen({
    super.key,
    required this.tableId,
    required this.tableLabel,
    this.existingOrder,
  });

  @override
  ConsumerState<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends ConsumerState<AddOrderScreen> {
  final Map<String, _CartItem> _cart = {};
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _vegOnly = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-populate if editing an existing order
    if (widget.existingOrder != null) {
      for (final item in widget.existingOrder!.items) {
        _cart[item.menuItemId] = _CartItem(
          itemId: item.menuItemId,
          name: item.menuItemName,
          price: item.unitPrice,
          quantity: item.quantity,
          notes: item.notes,
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double get _cartTotal =>
      _cart.values.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  int get _cartCount =>
      _cart.values.fold(0, (sum, item) => sum + item.quantity);

  void _updateQuantity(MenuItemDto menuItem, int change) {
    setState(() {
      final existing = _cart[menuItem.id];
      if (existing == null) {
        if (change > 0) {
          _cart[menuItem.id] = _CartItem(
            itemId: menuItem.id,
            name: menuItem.name,
            price: menuItem.price,
            quantity: change,
          );
        }
      } else {
        final newQty = existing.quantity + change;
        if (newQty <= 0) {
          _cart.remove(menuItem.id);
        } else {
          _cart[menuItem.id] = existing.copyWith(quantity: newQty);
        }
      }
    });
  }

  void _updateNotes(String itemId, String notes) {
    setState(() {
      final existing = _cart[itemId];
      if (existing != null) {
        _cart[itemId] = existing.copyWith(notes: notes.isEmpty ? null : notes);
      }
    });
  }

  Future<void> _submitOrder() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item to the order.'),
        ),
      );
      return;
    }

    try {
      final orderItems = _cart.values.map((item) {
        return OrderItemDto(
          id: 'item-${DateTime.now().millisecondsSinceEpoch}-${item.itemId}',
          menuItemId: item.itemId,
          menuItemName: item.name,
          quantity: item.quantity,
          unitPrice: item.price,
          notes: item.notes,
        );
      }).toList();

      final now = DateTime.now();

      if (widget.existingOrder != null) {
        // Edit flow
        final updatedOrder = OrderDto(
          id: widget.existingOrder!.id,
          tenantId: widget.existingOrder!.tenantId,
          tableId: widget.existingOrder!.tableId,
          tableLabel: widget.existingOrder!.tableLabel,
          status: widget.existingOrder!.status, // Keep original status
          items: orderItems,
          totalAmount: _cartTotal,
          staffId: widget.existingOrder!.staffId,
          staffName: widget.existingOrder!.staffName,
          notes: widget.existingOrder!.notes,
          createdAt: widget.existingOrder!.createdAt,
          updatedAt: now,
        );

        await ref.read(updateOrderProvider)(updatedOrder);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order updated successfully!')),
          );
          context.pop();
        }
      } else {
        // Create flow
        final newOrder = OrderDto(
          id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
          tenantId: 'mock-tenant-001',
          tableId: widget.tableId,
          tableLabel: widget.tableLabel,
          status: OrderStatus.pending,
          items: orderItems,
          totalAmount: _cartTotal,
          staffId: 'stf-001', // Default mock waiter
          staffName: 'Rahul (Waiter)',
          notes: null,
          createdAt: now,
          updatedAt: now,
        );

        await ref.read(createOrderProvider)(newOrder);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order sent to kitchen!')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit order: $e')));
      }
    }
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order Summary',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Text(
                        widget.tableLabel,
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: _cart.isEmpty
                        ? Center(
                            child: Text(
                              'Your cart is empty.',
                              style: GoogleFonts.inter(
                                color: AppTheme.secondary,
                              ),
                            ),
                          )
                        : ListView(
                            children: _cart.values.map((item) {
                              final textController = TextEditingController(
                                text: item.notes,
                              );
                              return Container(
                                margin: EdgeInsets.only(bottom: 12.h),
                                padding: EdgeInsets.all(12.r),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: AppTheme.surfaceContainer,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: GoogleFonts.inter(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Notes field
                                        Expanded(
                                          child: TextField(
                                            controller: textController,
                                            onChanged: (val) {
                                              _updateNotes(item.itemId, val);
                                              setSheetState(() {});
                                            },
                                            style: GoogleFonts.inter(
                                              fontSize: 12.sp,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Add kitchen note...',
                                              hintStyle: GoogleFonts.inter(
                                                fontSize: 11.sp,
                                                color: AppTheme.secondary,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                        // Quantity counter
                                        Row(
                                          children: [
                                            _CircularButton(
                                              icon: Icons.remove,
                                              onTap: () {
                                                final menuItem = MenuItemDto(
                                                  id: item.itemId,
                                                  name: item.name,
                                                  price: item.price,
                                                  tenantId: '',
                                                  categoryId: '',
                                                  isAvailable: true,
                                                  isVegetarian: false,
                                                  prepTimeMinutes: 15,
                                                  tags: [],
                                                );
                                                _updateQuantity(menuItem, -1);
                                                setSheetState(() {});
                                                setState(() {});
                                              },
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12.w,
                                              ),
                                              child: Text(
                                                '${item.quantity}',
                                                style:
                                                    GoogleFonts.jetBrainsMono(
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                            _CircularButton(
                                              icon: Icons.add,
                                              onTap: () {
                                                final menuItem = MenuItemDto(
                                                  id: item.itemId,
                                                  name: item.name,
                                                  price: item.price,
                                                  tenantId: '',
                                                  categoryId: '',
                                                  isAvailable: true,
                                                  isVegetarian: false,
                                                  prepTimeMinutes: 15,
                                                  tags: [],
                                                );
                                                _updateQuantity(menuItem, 1);
                                                setSheetState(() {});
                                                setState(() {});
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Bill',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.secondary,
                        ),
                      ),
                      Text(
                        '₹${_cartTotal.toStringAsFixed(0)}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: _cart.isEmpty
                        ? null
                        : () {
                            Navigator.pop(context);
                            _submitOrder();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryContainer,
                      minimumSize: Size(double.infinity, 50.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      widget.existingOrder != null
                          ? 'Update Kitchen Order'
                          : 'Send to Kitchen',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(menuCategoriesFutureProvider);
    final menuItemsAsync = ref.watch(menuItemsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existingOrder != null ? 'Edit Order' : 'Add Order',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            Text(
              'Table ${widget.tableLabel}',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: AppTheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Text(
                'Veg Only',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Switch(
                value: _vegOnly,
                onChanged: (val) => setState(() => _vegOnly = val),
                activeThumbColor: const Color(0xFF059669),
                activeTrackColor: const Color(0xFFA7F3D0),
              ),
            ],
          ),
          SizedBox(width: 8.w),
        ],
      ),
      bottomNavigationBar: _cart.isNotEmpty
          ? Material(
              elevation: 16,
              color: AppTheme.surfaceContainerLowest,
              child: SafeArea(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppTheme.surfaceContainer),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _showCartSheet,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.shopping_bag_outlined,
                                color: AppTheme.primaryContainer,
                                size: 18,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                '$_cartCount Items',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Total: ₹${_cartTotal.toStringAsFixed(0)}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      ElevatedButton(
                        onPressed: _submitOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryContainer,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 12.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text(
                          'Send',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().slideY(begin: 0.1, duration: 250.ms)
          : null,
      body: Column(
        children: [
          // Search & Filter
          Container(
            color: AppTheme.surfaceContainerLowest,
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search menu dishes...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.secondary,
                ),
                filled: true,
                fillColor: AppTheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 8.h),
              ),
            ),
          ),

          // Categories horizontal list
          categoriesAsync.when(
            loading: () => Container(height: 48.h, color: Colors.transparent),
            error: (err, _) => Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Error categories: $err',
                style: GoogleFonts.inter(color: AppTheme.error),
              ),
            ),
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();
              _selectedCategoryId ??= categories.first.id;

              return Container(
                height: 48.h,
                color: AppTheme.surfaceContainerLowest,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: categories.length + 1, // +1 for ALL
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final cat = isAll ? null : categories[index - 1];
                    final isSelected = isAll
                        ? _selectedCategoryId == ''
                        : _selectedCategoryId == cat?.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = isAll ? '' : cat!.id;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(
                          right: 8.w,
                          top: 4.h,
                          bottom: 8.h,
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryContainer
                              : AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Center(
                          child: Text(
                            isAll ? 'ALL ITEMS' : cat!.name.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.secondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Menu Grid list
          Expanded(
            child: menuItemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  'Error menu items: $err',
                  style: GoogleFonts.inter(color: AppTheme.error),
                ),
              ),
              data: (menuItems) {
                // Filter
                final items = menuItems.where((i) {
                  final matchesCategory =
                      _selectedCategoryId == null ||
                      _selectedCategoryId == '' ||
                      i.categoryId == _selectedCategoryId;
                  final matchesSearch =
                      i.name.toLowerCase().contains(_searchQuery) ||
                      (i.description?.toLowerCase().contains(_searchQuery) ??
                          false);
                  final matchesVeg = !_vegOnly || i.isVegetarian;
                  return matchesCategory && matchesSearch && matchesVeg;
                }).toList();

                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No menu items match your criteria.',
                      style: GoogleFonts.inter(color: AppTheme.secondary),
                    ),
                  );
                }

                return GridView.builder(
                  padding: EdgeInsets.all(16.r),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 2.8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final cartQty = _cart[item.id]?.quantity ?? 0;

                    return Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppTheme.surfaceContainer),
                        boxShadow: AppTheme.crimsonShadowLight,
                      ),
                      child: Row(
                        children: [
                          // Vegeterian indicator and name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _VegIndicator(isVeg: item.isVegetarian),
                                    SizedBox(width: 6.w),
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                if (item.description != null)
                                  Expanded(
                                    child: Text(
                                      item.description!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 10.sp,
                                        color: AppTheme.secondary,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Text(
                                      '₹${item.price.toStringAsFixed(0)}',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primaryContainer,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 10.r,
                                      color: AppTheme.secondary,
                                    ),
                                    SizedBox(width: 3.w),
                                    Text(
                                      '${item.prepTimeMinutes}m',
                                      style: GoogleFonts.inter(
                                        fontSize: 9.sp,
                                        color: AppTheme.secondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          // Control actions
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (cartQty == 0)
                                ElevatedButton(
                                  onPressed: item.isAvailable
                                      ? () => _updateQuantity(item, 1)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryContainer,
                                    disabledBackgroundColor:
                                        AppTheme.surfaceContainerHigh,
                                    minimumSize: Size(80.w, 36.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                  ),
                                  child: Text(
                                    item.isAvailable ? 'ADD' : '86D',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                      color: AppTheme.surfaceContainerHigh,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove,
                                          size: 14,
                                        ),
                                        onPressed: () =>
                                            _updateQuantity(item, -1),
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(
                                          maxWidth: 32.w,
                                          maxHeight: 32.h,
                                        ),
                                      ),
                                      Text(
                                        '$cartQty',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 14),
                                        onPressed: () =>
                                            _updateQuantity(item, 1),
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(
                                          maxWidth: 32.w,
                                          maxHeight: 32.h,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VegIndicator extends StatelessWidget {
  final bool isVeg;
  const _VegIndicator({required this.isVeg});

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? const Color(0xFF059669) : const Color(0xFFDC3545);
    return Container(
      width: 14.r,
      height: 14.r,
      padding: EdgeInsets.all(2.r),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(3.r),
      ),
      child: Container(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _CircularButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircularButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100.r),
      child: Container(
        width: 32.r,
        height: 32.r,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16.r, color: AppTheme.onSurface),
      ),
    );
  }
}

class _CartItem {
  final String itemId;
  final String name;
  final double price;
  final int quantity;
  final String? notes;

  _CartItem({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.notes,
  });

  _CartItem copyWith({int? quantity, String? notes}) {
    return _CartItem(
      itemId: itemId,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }
}
