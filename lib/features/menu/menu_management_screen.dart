import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/auth/app_auth_provider.dart';
import '../../core/data/dtos/menu_dto.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/menu_items_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/admin_shell.dart';
import 'presentation/screens/item_detail_screen.dart';
import 'presentation/screens/modifier_matrix_screen.dart';
import '../onboarding/presentation/state/onboarding_notifier.dart';
import 'package:uuid/uuid.dart';

final uuid = Uuid();

// ── Local Mock States for Interactive Operations ─────────────────────────────
final expandedCategoriesProvider = StateProvider<Map<String, bool>>(
  (ref) => {},
);

final categoryVisibilityProvider = StateProvider<Map<String, bool>>(
  (ref) => {},
);

final categorySchedulesProvider = StateProvider<Map<String, String?>>(
  (ref) => {},
);

class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() =>
      _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _toggleItemAvailability(MenuItemDto item) async {
    final currentVal = item.isAvailable;
    try {
      final updatedItem = item.copyWith(isAvailable: !currentVal);
      await ref.read(menuItemsProvider.notifier).updateMenuItem(updatedItem);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item.name} is now ${!currentVal ? 'Available' : 'Sold Out'}',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: !currentVal ? AppColors.success : AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update availability: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showAddCategorySheet(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLowest,
          title: Text(
            'Add Menu Category',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: GoogleFonts.plusJakartaSans(),
            decoration: InputDecoration(
              hintText: 'e.g. Chef Specials',
              hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.secondary),
            ),
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
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                final tenantId = ref.read(appContextProvider)?.tenant.id ?? '';
                if (tenantId.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No tenant context. Please sign in again.'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                  return;
                }

                final slug = MenuCategoryDto.slugify(name);
                final categoriesState = ref.read(categoriesProvider);
                final duplicate = categoriesState.byId.values.any(
                  (c) => c.resolvedSlug == slug,
                );
                if (duplicate) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Category "$name" already exists. Use the existing category or pick a different name.',
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                  return;
                }

                final newCategory = MenuCategoryDto(
                  id: uuid.v4(),
                  tenantId: tenantId,
                  name: name,
                  isActive: true,
                  sortOrder: 0,
                  versionNum: 1,
                );

                final result = await ref
                    .read(categoriesProvider.notifier)
                    .createCategory(newCategory);

                if (!context.mounted) return;

                if (result is Failure<MenuCategoryDto>) {
                  final message = result.error.code == ApiErrorCode.conflict
                      ? 'Category "$name" already exists.'
                      : 'Failed to create category: ${result.error.message}';
                  await ref
                      .read(categoriesProvider.notifier)
                      .loadCategories(forceRefresh: true);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTheme.error,
                    ),
                  );
                  return;
                }

                ref.invalidate(onboardingNotifierProvider);

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Category "$name" created successfully.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryContainer,
              ),
              child: Text(
                'Create',
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

  void _showItemEditSheet(
    BuildContext context,
    MenuItemDto? item,
    String defaultCatId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ItemDetailScreen(item: item, defaultCategoryId: defaultCatId),
      ),
    );
  }

  void _showScheduleDialog(BuildContext context, String catId, String catName) {
    final schedules = ref.read(categorySchedulesProvider);
    final currentSchedule = schedules[catId];
    final controller = TextEditingController(text: currentSchedule ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLowest,
          title: Text(
            'Schedule $catName',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set automated active hours or dayparting rules (e.g. 11:00 AM - 10:00 PM). Leave empty for All Day availability.',
                style: AppTheme.bodySm,
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.plusJakartaSans(fontSize: 13.sp),
                decoration: InputDecoration(
                  hintText: 'e.g. 11:00 AM - 10:00 PM',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: AppTheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Clear schedule
                ref.read(categorySchedulesProvider.notifier).state = {
                  ...ref.read(categorySchedulesProvider),
                  catId: null,
                };
                Navigator.pop(ctx);
              },
              child: Text(
                'Clear Schedule',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.error),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final schedule = controller.text.trim();
                ref.read(categorySchedulesProvider.notifier).state = {
                  ...ref.read(categorySchedulesProvider),
                  catId: schedule.isEmpty ? null : schedule,
                };
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryContainer,
              ),
              child: Text(
                'Save',
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

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final menuItemsState = ref.watch(menuItemsProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return AdminShell(
      title: 'Menu Manager',
      disablePadding: true,
      actions: isDesktop
          ? [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ModifierMatrixScreen()),
                  );
                },
                icon: Icon(Icons.tune_rounded, size: 16.r, color: AppTheme.primary),
                label: Text(
                  'Modifier Studio',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 11.sp,
                    color: AppTheme.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppTheme.primaryContainer.withValues(alpha: 0.3),
                  ),
                  minimumSize: Size(125.w, 38.h),
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              ElevatedButton.icon(
                onPressed: () => _showAddCategorySheet(context),
                icon: Icon(
                  Icons.create_new_folder_rounded,
                  size: 16.r,
                  color: Colors.white,
                ),
                label: Text(
                  'Add Category',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 11.sp,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(120.w, 38.h),
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              if (_selectedCategoryId != null) ...[
                SizedBox(width: 8.w),
                ElevatedButton.icon(
                  onPressed: () =>
                      _showItemEditSheet(context, null, _selectedCategoryId!),
                  icon: Icon(Icons.add_rounded, size: 16.r, color: Colors.white),
                  label: Text(
                    'Add Item',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.sp,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryContainer,
                    foregroundColor: Colors.white,
                    minimumSize: Size(100.w, 38.h),
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ],
            ]
          : [
              IconButton(
                icon: Icon(Icons.tune_rounded, color: AppTheme.primary, size: 22.r),
                tooltip: 'Modifier Studio',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ModifierMatrixScreen()),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.create_new_folder_rounded, color: AppTheme.primary, size: 22.r),
                tooltip: 'Add Category',
                onPressed: () => _showAddCategorySheet(context),
              ),
            ],
      body: isDesktop
          ? _buildTwoColumnLayout(categoriesState, menuItemsState)
          : _buildStackedLayout(categoriesState, menuItemsState),
    );
  }

  // ── 2-Column Desktop Layout ───────────────────────────────────────────────
  Widget _buildTwoColumnLayout(
    CategoriesState categoriesState,
    MenuItemsState menuItemsState,
  ) {
    if (categoriesState.isLoading && !categoriesState.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (categoriesState.error != null) {
      return Center(
        child: Text(
          'Failed to load categories: ${categoriesState.error}',
          style: GoogleFonts.plusJakartaSans(color: AppTheme.error),
        ),
      );
    }

    final categories = categoriesState.byId.values.toList();
    if (categories.isEmpty) {
      return Center(
        child: Text(
          'No categories found. Create one to get started!',
          style: GoogleFonts.plusJakartaSans(color: AppTheme.secondary),
        ),
      );
    }

        // Auto-select first category if none selected
        if (_selectedCategoryId == null && categories.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedCategoryId = categories.first.id;
              });
            }
          });
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Panel - Categories List
            Container(
              width: 320.w,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                border: Border(
                  right: BorderSide(color: AppTheme.surfaceContainerHigh),
                ),
              ),
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = _selectedCategoryId == category.id;

                  return Material(
                    color: isSelected
                        ? AppTheme.primaryContainer.withValues(alpha: 0.1)
                        : Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = category.id;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: isSelected
                                  ? AppTheme.primary
                                  : Colors.transparent,
                              width: 4.w,
                            ),
                            bottom: BorderSide(
                              color: AppTheme.surfaceContainerHigh,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_open_rounded,
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.secondary,
                              size: 20.r,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                category.name,
                                style: AppTheme.titleMd.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.onSurface,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.surfaceContainerHighest,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Right Panel - Items List
            Expanded(
              child: menuItemsState.isLoading && !menuItemsState.isInitialized
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : menuItemsState.error != null
                      ? Center(
                          child: Text(
                            'Failed to load menu: ${menuItemsState.error}',
                            style: GoogleFonts.plusJakartaSans(color: AppTheme.error),
                          ),
                        )
                      : Builder(
                          builder: (context) {
                            final menuItems = menuItemsState.byId.values.toList();
                  final catItems = menuItems
                      .where((i) => i.categoryId == _selectedCategoryId)
                      .toList();
                  final selectedCatName = categories
                      .firstWhere(
                        (c) => c.id == _selectedCategoryId,
                        orElse: () => categories.first,
                      )
                      .name;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 32.w,
                          vertical: 24.h,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppTheme.surfaceContainerHigh,
                            ),
                          ),
                        ),
                        child: Text(
                          selectedCatName,
                          style: AppTheme.headlineSm.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        child: catItems.isEmpty
                            ? Center(
                                child: Text(
                                  'No items in this category. Click "Add Item" to start.',
                                  style: AppTheme.bodySm.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 32.w,
                                  vertical: 24.h,
                                ),
                                itemCount: catItems.length,
                                separatorBuilder: (_, _) =>
                                    SizedBox(height: 12.h),
                                itemBuilder: (context, i) {
                                  return _buildNestedItemRow(
                                    catItems[i],
                                    _selectedCategoryId!,
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
  }

  // ── Stacked Mobile Layout (Fallback) ──────────────────────────────────────
  Widget _buildStackedLayout(
    CategoriesState categoriesState,
    MenuItemsState menuItemsState,
  ) {
    final expandedCategories = ref.watch(expandedCategoriesProvider);
    final categoryVisibility = ref.watch(categoryVisibilityProvider);
    final categorySchedules = ref.watch(categorySchedulesProvider);

    if (categoriesState.isLoading && !categoriesState.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (categoriesState.error != null) {
      return Center(
        child: Text(
          'Failed to load categories: ${categoriesState.error}',
          style: GoogleFonts.plusJakartaSans(color: AppTheme.error),
        ),
      );
    }

    if (menuItemsState.isLoading && !menuItemsState.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (menuItemsState.error != null) {
      return Center(
        child: Text(
          'Failed to load menu: ${menuItemsState.error}',
          style: GoogleFonts.plusJakartaSans(color: AppTheme.error),
        ),
      );
    }

    final categories = categoriesState.byId.values.toList();
    final menuItems = menuItemsState.byId.values.toList();

    if (categories.isEmpty) {
      return Center(
        child: Text(
          'No categories found. Create one to get started!',
          style: GoogleFonts.plusJakartaSans(color: AppTheme.secondary),
        ),
      );
    }

    return ReorderableListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
      itemCount: categories.length,
      onReorderItem: (oldIdx, newIdx) {},
      itemBuilder: (context, index) {
        final category = categories[index];
        final catId = category.id;
        final catName = category.name;
        final isExpanded = expandedCategories[catId] ?? true;
        final isVisible = categoryVisibility[catId] ?? true;
        final schedule = categorySchedules[catId];
        final catItems = menuItems
            .where((i) => i.categoryId == catId)
            .toList();

        return _buildCategoryAccordionCard(
          key: ValueKey(catId),
          catId: catId,
          catName: catName,
          items: catItems,
          isExpanded: isExpanded,
          isVisible: isVisible,
          schedule: schedule,
        );
      },
    );
  }

  // ── Accordion Category Card Widget ──────────────────────────────────────────
  Widget _buildCategoryAccordionCard({
    required Key key,
    required String catId,
    required String catName,
    required List<MenuItemDto> items,
    required bool isExpanded,
    required bool isVisible,
    required String? schedule,
  }) {
    final double opacity = isVisible ? 1.0 : 0.75;
    final String displayTitle = isVisible ? catName : '$catName (Hidden)';

    return Opacity(
      key: key,
      opacity: opacity,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isExpanded
                ? AppTheme.primaryContainer.withValues(alpha: 0.2)
                : AppTheme.surfaceContainerHigh,
            width: isExpanded ? 1.5.w : 1.w,
          ),
          boxShadow: isExpanded ? AppTheme.crimsonShadowLight : const [],
        ),
        child: Column(
          children: [
            // Accordion Title Bar
            InkWell(
              onTap: () {
                ref.read(expandedCategoriesProvider.notifier).state = {
                  ...ref.read(expandedCategoriesProvider),
                  catId: !isExpanded,
                };
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                child: Row(
                  children: [
                    // Drag handle
                    Icon(
                      Icons.drag_indicator_rounded,
                      color: AppTheme.secondary,
                      size: 20.r,
                    ),
                    SizedBox(width: 8.w),

                    // Info Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayTitle,
                            style: AppTheme.titleMd.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isVisible
                                  ? (isExpanded
                                        ? AppTheme.primary
                                        : AppTheme.onSurface)
                                  : AppTheme.secondary,
                            ),
                          ),
                          Text(
                            '${items.length} Items • ${schedule == null ? 'All Day' : 'Scheduled'}',
                            style: AppTheme.bodySm.copyWith(
                              fontSize: 10.sp,
                              color: AppTheme.secondary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Actions block
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Schedule Badge / Trigger
                        GestureDetector(
                          onTap: () =>
                              _showScheduleDialog(context, catId, catName),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: schedule != null
                                  ? AppTheme.primaryContainer.withValues(
                                      alpha: 0.1,
                                    )
                                  : AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(6.r),
                              border: schedule != null
                                  ? Border.all(
                                      color: AppTheme.primaryContainer
                                          .withValues(alpha: 0.2),
                                      width: 1.w,
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 11.r,
                                  color: schedule != null
                                      ? AppTheme.primary
                                      : AppTheme.secondary,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  schedule ?? 'Schedule',
                                  style: AppTheme.labelSm.copyWith(
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.w700,
                                    color: schedule != null
                                        ? AppTheme.primary
                                        : AppTheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),

                        // Visibility Toggle
                        GestureDetector(
                          onTap: () {
                            ref
                                .read(categoryVisibilityProvider.notifier)
                                .state = {
                              ...ref.read(categoryVisibilityProvider),
                              catId: !isVisible,
                            };
                          },
                          child: AnimatedContainer(
                            duration: 200.ms,
                            width: 38.w,
                            height: 20.h,
                            decoration: BoxDecoration(
                              color: isVisible
                                  ? AppTheme.primaryContainer
                                  : AppTheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: AnimatedAlign(
                              duration: 200.ms,
                              alignment: isVisible
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: EdgeInsets.all(2.r),
                                width: 16.r,
                                height: 16.r,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),

                        // Expand indicator
                        Icon(
                          isExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: isExpanded
                              ? AppTheme.primary
                              : AppTheme.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Nested Expanded Items List
            if (isExpanded) ...[
              Divider(
                height: 1.h,
                thickness: 1.h,
                color: AppTheme.surfaceContainerHigh,
              ),
              Container(
                color: AppTheme.surfaceContainerLow.withValues(alpha: 0.4),
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                child: Column(
                  children: [
                    if (items.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.h),
                        child: Text(
                          'No items in this category. Tap below to add.',
                          style: AppTheme.bodySm.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => SizedBox(height: 8.h),
                        itemBuilder: (context, i) {
                          final item = items[i];
                          return _buildNestedItemRow(item, catId);
                        },
                      ),
                    SizedBox(height: 12.h),

                    // Add Item Button in this category
                    InkWell(
                      onTap: () => _showItemEditSheet(context, null, catId),
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.primaryContainer.withValues(
                              alpha: 0.2,
                            ),
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 14.r,
                              color: AppTheme.primary,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Add Item to $catName',
                              style: AppTheme.labelSm.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Nested Category Item Row Widget ─────────────────────────────────────────
  Widget _buildNestedItemRow(MenuItemDto item, String catId) {
    IconData itemIcon = Icons.lunch_dining_rounded;
    if (catId == 'cat-004') itemIcon = Icons.local_cafe_rounded;
    if (catId == 'cat-005') itemIcon = Icons.icecream_rounded;
    if (catId == 'cat-001') itemIcon = Icons.bakery_dining_rounded;

    return Opacity(
      opacity: item.isAvailable ? 1.0 : 0.6,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppTheme.surfaceContainerHigh, width: 1.w),
        ),
        child: Row(
          children: [
            // Reorder item indicator
            Icon(
              Icons.drag_indicator_rounded,
              color: AppTheme.surfaceContainerHighest,
              size: 16.r,
            ),
            SizedBox(width: 6.w),

            // Circle icon / Image preview
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6.r),
                image: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(item.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: item.imageUrl == null || item.imageUrl!.isEmpty
                  ? Icon(itemIcon, size: 16.r, color: AppTheme.secondary)
                  : null,
            ),
            SizedBox(width: 10.w),

            // Item Metadata Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTheme.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.sp,
                      color: item.isAvailable
                          ? AppTheme.onSurface
                          : AppTheme.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.isAvailable
                        ? '₹${(item.basePriceAmount / 100).toStringAsFixed(2)}'
                        : '₹${(item.basePriceAmount / 100).toStringAsFixed(2)} (Sold Out)',
                    style: AppTheme.bodySm.copyWith(
                      fontSize: 10.sp,
                      color: item.isAvailable
                          ? AppTheme.primary
                          : AppTheme.secondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Interactive availability slider
            GestureDetector(
              onTap: () => _toggleItemAvailability(item),
              child: AnimatedContainer(
                duration: 200.ms,
                width: 32.w,
                height: 18.h,
                decoration: BoxDecoration(
                  color: item.isAvailable
                      ? AppTheme.primaryContainer
                      : AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: AnimatedAlign(
                  duration: 200.ms,
                  alignment: item.isAvailable
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.all(1.5.r),
                    width: 15.r,
                    height: 15.r,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),

            // Edit Item button
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                size: 16.r,
                color: AppTheme.secondary,
              ),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: () => _showItemEditSheet(context, item, catId),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail Edit/Add Item Sheet ────────────────────────────────────────────────
class _MenuItemSheet extends ConsumerStatefulWidget {
  final MenuItemDto? item;
  final String defaultCategoryId;
  const _MenuItemSheet({required this.defaultCategoryId}) : item = null;

  @override
  ConsumerState<_MenuItemSheet> createState() => _MenuItemSheetState();
}

class _MenuItemSheetState extends ConsumerState<_MenuItemSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _prepTimeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  late String _categoryId;
  bool _available = true;
  bool _isVegetarian = false;
  bool _isSaving = false;
  XFile? _pickedImage;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtrl.text = item?.name ?? '';
    _priceCtrl.text = item != null ? (item.basePriceAmount / 100).toStringAsFixed(0) : '';
    _prepTimeCtrl.text = item != null ? item.prepTimeMinutes.toString() : '15';
    _descCtrl.text = item?.description ?? '';
    _available = item?.isAvailable ?? true;
    _isVegetarian = item?.isVegetarian ?? false;
    _currentImageUrl = item?.imageUrl;
    _categoryId = item?.categoryId ?? widget.defaultCategoryId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _prepTimeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) setState(() => _pickedImage = image);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an item name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final appContext = ref.read(appContextProvider);
      final tenantId = appContext?.tenant.id ?? '';
      if (tenantId.isEmpty) {
        throw StateError('No tenant context');
      }

      final Result<MenuItemDto> result;
      if (widget.item == null) {
        final newItem = MenuItemDto(
          id: 'menu-item-${uuid.v4()}',
          tenantId: tenantId,
          categoryId: _categoryId,
          name: name,
          description: _descCtrl.text.trim(),
          basePriceAmount: ((double.tryParse(_priceCtrl.text) ?? 0) * 100).round(),
          imageUrl: _pickedImage != null
              ? _pickedImage!.path
              : _currentImageUrl,
          isAvailable: _available,
          isVegetarian: _isVegetarian,
          prepTimeMinutes: int.tryParse(_prepTimeCtrl.text) ?? 15,
          tags: [],
          versionNum: 1,
        );
        result = await ref.read(menuItemsProvider.notifier).createMenuItem(newItem);
      } else {
        final updated = MenuItemDto(
          id: widget.item!.id,
          tenantId: widget.item!.tenantId,
          categoryId: _categoryId,
          name: name,
          description: _descCtrl.text.trim(),
          basePriceAmount: ((double.tryParse(_priceCtrl.text) ?? (widget.item!.basePriceAmount / 100)) * 100).round(),
          imageUrl: _pickedImage != null
              ? _pickedImage!.path
              : _currentImageUrl,
          isAvailable: _available,
          isVegetarian: _isVegetarian,
          prepTimeMinutes:
              int.tryParse(_prepTimeCtrl.text) ?? widget.item!.prepTimeMinutes,
          tags: widget.item!.tags,
          versionNum: widget.item!.versionNum,
        );
        result = await ref.read(menuItemsProvider.notifier).updateMenuItem(updated);
      }

      if (!mounted) return;

      if (result is Failure<MenuItemDto>) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: ${result.error.message}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    if (widget.item == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        title: const Text('Delete Item?'),
        content: Text(
          'Are you sure you want to delete "${widget.item!.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(menuItemsProvider.notifier).deleteMenuItem(widget.item!.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: EdgeInsets.only(bottom: 16.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.item == null ? 'Add Menu Item' : 'Edit Item',
                    style: AppTheme.titleLg.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (widget.item != null)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: AppTheme.error,
                        size: 22.r,
                      ),
                      onPressed: _delete,
                    ),
                ],
              ),
              SizedBox(height: 16.h),

              // Item Name field
              _buildField('Item Name', _nameCtrl, 'e.g. Classic Cheeseburger'),
              SizedBox(height: 12.h),

              // Row for Price + Prep time
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      'Price (₹)',
                      _priceCtrl,
                      'e.g. 14.99',
                      type: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildField(
                      'Prep Time (Mins)',
                      _prepTimeCtrl,
                      'e.g. 15',
                      type: TextInputType.number,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Description
              _buildField(
                'Description',
                _descCtrl,
                'Enter food descriptions, allergy info...',
                maxLines: 2,
              ),
              SizedBox(height: 16.h),

              // Image Selector
              Text(
                'Item Image',
                style: AppTheme.labelSm.copyWith(color: AppTheme.secondary),
              ),
              SizedBox(height: 6.h),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 110.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: AppTheme.surfaceContainerHigh),
                  ),
                  child: _pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: Image.file(
                            File(_pickedImage!.path),
                            fit: BoxFit.cover,
                          ),
                        )
                      : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child:
                              _currentImageUrl!.startsWith('/') ||
                                  _currentImageUrl!.contains('cache')
                              ? Image.file(
                                  File(_currentImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  _currentImageUrl!,
                                  fit: BoxFit.cover,
                                ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 24.r,
                                color: AppTheme.secondary,
                              ),
                              SizedBox(height: 4.h),
                              Text('Add Food Photo', style: AppTheme.bodySm),
                            ],
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16.h),

              // Dietary + Stock options
              SwitchListTile(
                title: Text(
                  'Vegetarian Diet',
                  style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Displays green vegetarian icon to guests',
                  style: AppTheme.bodySm,
                ),
                value: _isVegetarian,
                activeThumbColor: AppTheme.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _isVegetarian = val),
              ),

              SwitchListTile(
                title: Text(
                  'Currently Available',
                  style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Instantly toggles visibility on diner devices',
                  style: AppTheme.bodySm,
                ),
                value: _available,
                activeThumbColor: AppTheme.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _available = val),
              ),
              SizedBox(height: 24.h),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppTheme.surfaceContainerHigh,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryContainer,
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 20.r,
                              height: 20.r,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Save Item',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelSm.copyWith(color: AppTheme.secondary),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: ctrl,
          keyboardType: type,
          maxLines: maxLines,
          style: GoogleFonts.plusJakartaSans(fontSize: 13.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: AppTheme.secondary,
              fontSize: 13.sp,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(
                color: AppTheme.surfaceContainerHigh,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(
                color: AppTheme.surfaceContainerHigh,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: maxLines > 1 ? 12.h : 8.h,
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

