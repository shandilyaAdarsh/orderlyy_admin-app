import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/auth/mock_auth_provider.dart';
import '../../core/data/dtos/menu_dto.dart';
import '../../core/providers/menu_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/uuid.dart';

// ── Constants ─────────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFFC0272D);
const _kCategories = [
  'ALL',
  'STARTERS',
  'MAINS',
  'SIDES',
  'DESSERTS',
  'BEVERAGES',
];

// ── Screen ────────────────────────────────────────────────────────────────────
class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() =>
      _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  int _catIndex = 0;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MenuItemDto> _filtered(List<MenuItemDto> items) {
    var list = items;
    if (_catIndex > 0) {
      final cat = _kCategories[_catIndex];
      list = list
          .where(
            (i) =>
                i.name.toUpperCase().contains(cat) ||
                i.categoryId.toUpperCase().contains(cat),
          )
          .toList();
    }
    if (_search.isNotEmpty) {
      list = list
          .where((i) => i.name.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }
    return list;
  }

  Future<void> _toggleAvailability(MenuItemDto item) async {
    final newVal = !item.isAvailable;
    try {
      await ref.read(toggleMenuItemAvailabilityProvider)(item.id, newVal);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update availability: $e'),
            backgroundColor: _kPrimary,
          ),
        );
      }
    }
  }

  void _showEditSheet(BuildContext context, MenuItemDto? item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MenuItemSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuItemsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SafeArea(
        child: menuAsync.when(
          error: (err, _) => Center(
            child: Text(
              'Failed to load menu: $err',
              style: GoogleFonts.inter(color: AppTheme.error),
            ),
          ),
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _kPrimary)),
          data: (allItems) {
            final filtered = _filtered(allItems);
            return CustomScrollView(
              slivers: [
                // ── App Bar ───────────────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 1,
                  toolbarHeight: 64.h,
                  shadowColor: const Color(0xFFE2E8F0),
                  automaticallyImplyLeading: false,
                  title: Row(
                    children: [
                      Text(
                        'Orderlli',
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                          color: _kPrimary,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Container(
                        width: 1.w,
                        height: 20.h,
                        color: const Color(0xFFE2E8F0),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Menu',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          '${allItems.length}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.add_rounded,
                        color: _kPrimary,
                        size: 24.r,
                      ),
                      onPressed: () => _showEditSheet(context, null),
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(108.h),
                    child: Column(
                      children: [
                        // Search
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _search = v),
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search menu items...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: const Color(0xFF94A3B8),
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: const Color(0xFF94A3B8),
                                size: 20.r,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFB),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 0.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                                borderSide: const BorderSide(color: _kPrimary),
                              ),
                            ),
                          ),
                        ),
                        // Category tabs
                        SizedBox(
                          height: 44.h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            itemCount: _kCategories.length,
                            itemBuilder: (context, i) {
                              final active = _catIndex == i;
                              return GestureDetector(
                                onTap: () => setState(() => _catIndex = i),
                                child: AnimatedContainer(
                                  duration: 200.ms,
                                  margin: EdgeInsets.only(right: 8.w),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? _kPrimary
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _kCategories[i],
                                      style: GoogleFonts.inter(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w700,
                                        color: active
                                            ? Colors.white
                                            : const Color(0xFF64748B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 8.h),
                      ],
                    ),
                  ),
                ),

                // ── Body ──────────────────────────────────────────────────────
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.restaurant_menu_outlined,
                            size: 64.r,
                            color: const Color(
                              0xFFCBD5E1,
                            ).withValues(alpha: 0.6),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No items found',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, i) {
                        return _MenuItemCard(
                              item: filtered[i],
                              onToggle: () => _toggleAvailability(filtered[i]),
                              onTap: () => _showEditSheet(context, filtered[i]),
                            )
                            .animate(delay: Duration(milliseconds: 40 * i))
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.1, curve: Curves.easeOut);
                      }, childCount: filtered.length),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Menu Item Card ────────────────────────────────────────────────────────────
class _MenuItemCard extends StatelessWidget {
  final MenuItemDto item;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _MenuItemCard({
    required this.item,
    required this.onToggle,
    required this.onTap,
  });

  Color get _catColor {
    final cat = item.categoryId.toUpperCase();
    if (cat.contains('START') || cat == 'CAT-001') {
      return const Color(0xFFF59E0B);
    }
    if (cat.contains('MAIN') || cat == 'CAT-002') return _kPrimary;
    if (cat.contains('DESSERT') || cat == 'CAT-005') {
      return const Color(0xFFEC4899);
    }
    if (cat.contains('BEV') || cat == 'CAT-004') {
      return const Color(0xFF3B82F6);
    }
    if (cat.contains('BREAD') || cat == 'CAT-003') {
      return const Color(0xFF10B981);
    }
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Opacity(
          opacity: item.isAvailable ? 1.0 : 0.6,
          child: Row(
            children: [
              // Image placeholder or network image
              Container(
                width: 60.r,
                height: 60.r,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12.r),
                  image: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(item.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: item.imageUrl == null || item.imageUrl!.isEmpty
                    ? Icon(
                        Icons.restaurant_rounded,
                        color: AppTheme.secondary.withValues(alpha: 0.5),
                        size: 24.r,
                      )
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '₹${item.price.toStringAsFixed(0)}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: _catColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            item.categoryId.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: _catColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (item.isVegetarian) ...[
                          SizedBox(width: 6.w),
                          Container(
                            width: 14.r,
                            height: 14.r,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF16A34A),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                            child: Center(
                              child: Container(
                                width: 7.r,
                                height: 7.r,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF16A34A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Availability toggle
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: 200.ms,
                  width: 44.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: item.isAvailable
                        ? _kPrimary
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(2.r),
                    child: AnimatedAlign(
                      duration: 200.ms,
                      alignment: item.isAvailable
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 20.r,
                        height: 20.r,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
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

// ── Add / Edit Bottom Sheet ───────────────────────────────────────────────────
class _MenuItemSheet extends ConsumerStatefulWidget {
  final MenuItemDto? item;
  const _MenuItemSheet({this.item});

  @override
  ConsumerState<_MenuItemSheet> createState() => _MenuItemSheetState();
}

class _MenuItemSheetState extends ConsumerState<_MenuItemSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _customCatCtrl = TextEditingController();
  String _category = 'MAINS';
  bool _available = true;
  bool _isVegetarian = false;
  bool _isSaving = false;
  XFile? _pickedImage;
  String? _currentImageUrl;
  bool _useCustomCat = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtrl.text = item?.name ?? '';
    _priceCtrl.text = item != null ? item.price.toStringAsFixed(0) : '';
    _available = item?.isAvailable ?? true;
    _isVegetarian = item?.isVegetarian ?? false;
    _currentImageUrl = item?.imageUrl;

    // Map categoryId to display category
    final catId = item?.categoryId.toUpperCase() ?? '';
    _category = _catIdToLabel(catId);
    if (!_kCategories.contains(_category) && _category != 'ALL') {
      _useCustomCat = true;
      _customCatCtrl.text = _category;
      _category = 'OTHER';
    }
  }

  String _catIdToLabel(String catId) {
    return switch (catId) {
      'CAT-001' => 'STARTERS',
      'CAT-002' => 'MAINS',
      'CAT-003' => 'SIDES',
      'CAT-004' => 'BEVERAGES',
      'CAT-005' => 'DESSERTS',
      _ => catId.isNotEmpty ? catId : 'MAINS',
    };
  }

  String _catLabelToId(String label) {
    return switch (label) {
      'STARTERS' => 'cat-001',
      'MAINS' => 'cat-002',
      'SIDES' => 'cat-003',
      'BEVERAGES' => 'cat-004',
      'DESSERTS' => 'cat-005',
      _ => 'cat-002',
    };
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _customCatCtrl.dispose();
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

  // Image upload is intentionally a no-op in mock mode.
  // The SupabaseMenuRepository will handle actual storage upload when wired.
  Future<String?> _resolveImageUrl() async {
    if (_pickedImage == null) return _currentImageUrl;
    // TODO: delegate to repository image upload when SupabaseMenuRepository
    // is implemented. For now, return the existing URL unchanged.
    return _currentImageUrl;
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item name')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final appContext = ref.read(appContextProvider);
      final tenantId = appContext?.tenant.id ?? '';
      if (tenantId.isEmpty) {
        throw Exception('Tenant context is not yet loaded.');
      }
      final imageUrl = await _resolveImageUrl();
      final categoryLabel = _useCustomCat
          ? _customCatCtrl.text.trim().toUpperCase()
          : _category;
      final categoryId = _catLabelToId(categoryLabel);

      if (widget.item == null) {
        // Create
        final newItem = MenuItemDto(
          id: UuidGenerator.generateRuntimeId(prefix: 'menu-item'),
          tenantId: tenantId,
          categoryId: categoryId,
          name: name,
          price: double.tryParse(_priceCtrl.text) ?? 0,
          imageUrl: imageUrl,
          isAvailable: _available,
          isVegetarian: _isVegetarian,
          prepTimeMinutes: 15,
          tags: [],
        );
        await ref.read(createMenuItemProvider)(newItem);
      } else {
        // Update
        final updated = MenuItemDto(
          id: widget.item!.id,
          tenantId: widget.item!.tenantId,
          categoryId: categoryId,
          name: name,
          description: widget.item!.description,
          price: double.tryParse(_priceCtrl.text) ?? widget.item!.price,
          imageUrl: imageUrl,
          isAvailable: _available,
          isVegetarian: _isVegetarian,
          prepTimeMinutes: widget.item!.prepTimeMinutes,
          tags: widget.item!.tags,
        );
        await ref.read(updateMenuItemProvider)(updated);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: _kPrimary,
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
      await ref.read(deleteMenuItemProvider)(widget.item!.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting: $e'),
            backgroundColor: _kPrimary,
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
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 12.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item == null ? 'Add Menu Item' : 'Edit Item',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    _field('Item Name', _nameCtrl, 'e.g. Butter Chicken'),
                    SizedBox(height: 12.h),
                    _field(
                      'Price',
                      _priceCtrl,
                      'e.g. 350',
                      type: TextInputType.number,
                    ),
                    SizedBox(height: 16.h),
                    // Image Picker
                    Text(
                      'Item Image',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 120.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFB),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: _pickedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: Image.file(
                                  File(_pickedImage!.path),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _currentImageUrl != null &&
                                  _currentImageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: Image.network(
                                  _currentImageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    color: const Color(0xFF94A3B8),
                                    size: 32.r,
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Tap to upload image',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Category',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 6.h,
                      children: [..._kCategories.skip(1), 'OTHER'].map((cat) {
                        final active = _category == cat;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _category = cat;
                            _useCustomCat = (cat == 'OTHER');
                          }),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? _kPrimary
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              cat,
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: active
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_useCustomCat) ...[
                      SizedBox(height: 12.h),
                      _field('Custom Category', _customCatCtrl, 'e.g. BREAD'),
                    ],
                    SizedBox(height: 16.h),
                    // Vegetarian toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Vegetarian',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8.r,
                          child: Switch(
                            value: _isVegetarian,
                            onChanged: (v) => setState(() => _isVegetarian = v),
                            activeThumbColor: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    // Available toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8.r,
                          child: Switch(
                            value: _available,
                            onChanged: (v) => setState(() => _available = v),
                            activeThumbColor: _kPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    // Action buttons
                    Row(
                      children: [
                        if (widget.item != null) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _delete,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _kPrimary,
                                side: const BorderSide(color: _kPrimary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                              ),
                              child: Text(
                                'Delete',
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                        ],
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? SizedBox(
                                    width: 20.r,
                                    height: 20.r,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Save Item',
                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType? type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: ctrl,
          keyboardType: type,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0xFFCBD5E1),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFB),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 12.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: _kPrimary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
