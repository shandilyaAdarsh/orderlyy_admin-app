// lib/features/customer/presentation/screens/customer_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../menu/domain/entities/menu_snapshot.dart';
import '../../../menu/presentation/state/menu_providers.dart';
import '../state/customer_providers.dart';
import '../widgets/customer_cart_sheet.dart';
import '../widgets/customer_components.dart';
import '../widgets/modifier_selection_sheet.dart';

class CustomerMenuScreen extends ConsumerStatefulWidget {
  const CustomerMenuScreen({super.key});

  @override
  ConsumerState<CustomerMenuScreen> createState() => _CustomerMenuScreenState();
}

class _CustomerMenuScreenState extends ConsumerState<CustomerMenuScreen> {
  String _selectedCategoryId = 'all';
  String _searchQuery = '';
  bool _filterVegOnly = false;

  @override
  void initState() {
    super.initState();
    // Enable background availability polling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(menuAvailabilityPollingProvider);
    });
  }

  bool _isItemVeg(MenuItem item) {
    final name = item.name.toLowerCase();
    final desc = item.description.toLowerCase();
    final nonVegWords = ['chicken', 'beef', 'pork', 'meat', 'fish', 'prawn', 'mutton', 'lamb', 'egg'];
    return !nonVegWords.any((word) => name.contains(word) || desc.contains(word));
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuSnapshotNotifierProvider);
    final session = ref.watch(customerSessionProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orderlyy Digital Menu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            context.go('/splash');
          },
        ),
        actions: [
          // Display Table info in app bar
          if (session != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Table ${session.tableId}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: menuAsync.when(
        loading: () => _buildShimmerLoader(),
        error: (err, stack) => _buildErrorState(err),
        data: (snapshot) {
          // Perform filtering
          final filteredItems = snapshot.items.where((item) {
            // Category filter
            if (_selectedCategoryId != 'all' && item.categoryId != _selectedCategoryId) {
              return false;
            }
            // Veg filter
            if (_filterVegOnly && !_isItemVeg(item)) {
              return false;
            }
            // Search query filter
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              final matchesName = item.name.toLowerCase().contains(query);
              final matchesDesc = item.description.toLowerCase().contains(query);
              return matchesName || matchesDesc;
            }
            return true;
          }).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth >= 600;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search & Filter Header
                  _buildSearchAndFilters(isDark),
                  // Category Tabs
                  _buildCategoryTabs(snapshot.categories, isDark),
                  // Menu Items Grid/List
                  Expanded(
                    child: filteredItems.isEmpty
                        ? _buildEmptyState(theme, isDark)
                        : (isTablet
                            ? _buildTabletGrid(filteredItems, snapshot.modifierGroups, theme, isDark)
                            : _buildMobileList(filteredItems, snapshot.modifierGroups, theme, isDark)),
                  ),
                  // Persistent Cart Bar at bottom
                  if (session != null && session.cart.isNotEmpty)
                    _buildPersistentCartBar(session.cart.length, session.subtotal.formatted, isDark),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Column(
      children: [
        // Search bar skeleton
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: SkeletonLoader(height: 52, width: double.infinity, borderRadius: 16),
        ),
        // Categories list skeleton
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 4,
            itemBuilder: (context, index) => const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: SkeletonLoader(height: 36, width: 80, borderRadius: 18),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Grid cards skeleton
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisExtent: 150,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => const SkeletonLoader(height: 150, width: 200, borderRadius: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(Object err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to load menu snapshot', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(err.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(
              width: 150,
              child: AppButton(
                label: 'Retry',
                onPressed: () {
                  ref.read(menuSnapshotNotifierProvider.notifier).loadMenu(forceRefresh: true);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          const SizedBox(height: 12),
          Text(
            'No matching items found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search items...',
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Veg filter chip
          FilterChip(
            selected: _filterVegOnly,
            label: const Row(
              children: [
                VegIndicator(isVeg: true),
                SizedBox(width: 6),
                Text('Veg Only', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            onSelected: (val) {
              setState(() {
                _filterVegOnly = val;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(List<MenuCategory> categories, bool isDark) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final catId = isAll ? 'all' : categories[index - 1].id;
          final label = isAll ? 'All Items' : categories[index - 1].name;
          final isSelected = _selectedCategoryId == catId;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(label),
              selectedColor: AppColors.primary,
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: FontWeight.bold,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategoryId = catId;
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileList(
    List<MenuItem> items,
    List<ModifierGroup> modifierGroups,
    ThemeData theme,
    bool isDark,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isAvailable = item.isAvailable;
        final isVeg = _isItemVeg(item);

        return Semantics(
          label: '${item.name}, Price: ${item.price.formatted}',
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Opacity(
              opacity: isAvailable ? 1.0 : 0.5,
              child: AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Veg Indicator & Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              VegIndicator(isVeg: isVeg),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (item.description.isNotEmpty)
                            Text(
                              item.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 8),
                          Text(
                            item.price.formatted,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Action button
                    _buildItemActionButton(item, modifierGroups, isAvailable),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabletGrid(
    List<MenuItem> items,
    List<ModifierGroup> modifierGroups,
    ThemeData theme,
    bool isDark,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisExtent: 180,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isAvailable = item.isAvailable;
        final isVeg = _isItemVeg(item);

        return Opacity(
          opacity: isAvailable ? 1.0 : 0.5,
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VegIndicator(isVeg: isVeg),
                    Text(
                      item.price.formatted,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      item.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: _buildItemActionButton(item, modifierGroups, isAvailable),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemActionButton(MenuItem item, List<ModifierGroup> modifierGroups, bool isAvailable) {
    if (!isAvailable) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: Alignment.center,
        child: const Text(
          'OUT OF STOCK',
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      );
    }

    final hasModifiers = item.modifierGroupIds.isNotEmpty;

    return Semantics(
      label: 'Add ${item.name} to cart button',
      button: true,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          final itemGroups = modifierGroups.where((g) => item.modifierGroupIds.contains(g.id)).toList();
          if (hasModifiers) {
            // Open Modifier Selection bottom-sheet
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (context) => ModifierSelectionSheet(
                item: item,
                modifierGroups: itemGroups,
                onConfirm: (qty, selectedOpts) {
                  ref.read(customerSessionProvider.notifier).addToCart(item, qty, selectedOpts);
                },
              ),
            );
          } else {
            // Simple fast add to cart
            ref.read(customerSessionProvider.notifier).addToCart(item, 1, const []);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added ${item.name} to cart'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
        child: const Text(
          'ADD',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPersistentCartBar(int count, String total, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count item${count > 1 ? "s" : ""} selected',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  total,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 140,
              child: AppButton(
                label: 'View Cart',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (context) => const CustomerCartSheet(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
