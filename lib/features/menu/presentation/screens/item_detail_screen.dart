import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/data/dtos/menu_dto.dart';
import '../../../../core/data/dtos/menu_recommendation_dto.dart';
import '../../../../core/providers/categories_provider.dart';
import '../../../../core/providers/menu_items_provider.dart';
import '../../../../core/providers/menu_recommendations_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/app_auth_provider.dart';
import '../../../../core/network/api_exception.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class ItemDetailScreen extends ConsumerStatefulWidget {
  final MenuItemDto? item;
  final String? defaultCategoryId;

  const ItemDetailScreen({super.key, this.item, this.defaultCategoryId});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late String _categoryId;

  bool _available = true;
  bool _recommendationEnabled = true;
  List<String> _recommendationTags = [];
  late TextEditingController _recTagCtrl;
  bool _isSaving = false;
  XFile? _pickedImage;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    final item = widget.item;

    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _descCtrl = TextEditingController(text: item?.description ?? '');
    _priceCtrl = TextEditingController(
      text: item != null ? (item.basePriceAmount / 100).toStringAsFixed(2) : '',
    );
    _categoryId = item?.categoryId ?? widget.defaultCategoryId ?? '';
    _available = item?.isAvailable ?? true;
    _currentImageUrl = item?.imageUrl ?? '';
    _recommendationEnabled = item?.recommendationEnabled ?? true;
    _recommendationTags = List<String>.from(item?.recommendationTags ?? []);
    _recTagCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _recTagCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Future<void> _saveItem() async {
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

    if (_categoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final normalizedRecTags = _recommendationTags
          .map((t) => t.trim().toLowerCase())
          .where((t) => t.isNotEmpty)
          .toSet()
          .toList();

      final Result<MenuItemDto> result;
      if (widget.item != null) {
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
          isVegetarian: widget.item!.isVegetarian,
          prepTimeMinutes: widget.item!.prepTimeMinutes,
          tags: widget.item!.tags,
          recommendationEnabled: _recommendationEnabled,
          recommendationTags: normalizedRecTags,
          versionNum: widget.item!.versionNum,
        );
        result = await ref.read(menuItemsProvider.notifier).updateMenuItem(updated);
      } else {
        final tenantId = ref.read(appContextProvider)?.tenant.id ?? '';
        final newItem = MenuItemDto(
          id: uuid.v4(),
          tenantId: tenantId,
          categoryId: _categoryId,
          name: name,
          description: _descCtrl.text.trim(),
          basePriceAmount: ((double.tryParse(_priceCtrl.text) ?? 0.0) * 100).round(),
          imageUrl: _pickedImage != null
              ? _pickedImage!.path
              : _currentImageUrl,
          isAvailable: _available,
          isVegetarian: false,
          prepTimeMinutes: 15,
          tags: [],
          recommendationEnabled: _recommendationEnabled,
          recommendationTags: normalizedRecTags,
          versionNum: 1,
        );
        result = await ref.read(menuItemsProvider.notifier).createMenuItem(newItem);
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item "$name" saved successfully.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final categories = categoriesState.byId.values.toList();
    final recsState = widget.item != null
        ? ref.watch(itemRecommendationsProvider(widget.item!.id))
        : null;

    if (categories.isNotEmpty && !categories.any((c) => c.id == _categoryId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _categoryId = categories.first.id;
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.item == null ? 'Add Menu Item' : 'Edit Item',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: AppTheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            size: 22.r,
            color: AppTheme.secondary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
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
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 600.w),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Area (Item Name + Availability)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _nameCtrl.text.isEmpty ? 'New Item' : _nameCtrl.text,
                          style: AppTheme.displayLg.copyWith(fontSize: 32.sp),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: _available
                              ? const Color(0xFF10B981).withValues(alpha: 0.1)
                              : AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: _available
                                ? const Color(0xFF10B981)
                                : AppTheme.error,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _available
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              size: 14.r,
                              color: _available
                                  ? const Color(0xFF10B981)
                                  : AppTheme.error,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              _available ? 'Active' : 'Hidden',
                              style: AppTheme.labelSm.copyWith(
                                color: _available
                                    ? const Color(0xFF10B981)
                                    : AppTheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // Actions (Discard / Save)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppTheme.surfaceContainerHigh,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            'Discard Changes',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            elevation: 0,
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
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save_rounded, size: 18.r),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Save Item',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),

                  // 2. Item Media
                  _buildSectionTitle(Icons.image_outlined, 'Item Media'),
                  SizedBox(height: 12.h),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 240.h,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppTheme.surfaceContainerHigh,
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _pickedImage != null
                          ? Image.file(
                              File(_pickedImage!.path),
                              fit: BoxFit.cover,
                            )
                          : _currentImageUrl != null &&
                                _currentImageUrl!.isNotEmpty
                          ? (_currentImageUrl!.startsWith('/') ||
                                    _currentImageUrl!.contains('cache')
                                ? Image.file(
                                    File(_currentImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    _currentImageUrl!,
                                    fit: BoxFit.cover,
                                  ))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 48.r,
                                  color: AppTheme.secondary,
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  'Tap to upload item photo',
                                  style: AppTheme.bodyMd.copyWith(
                                    color: AppTheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // 3. Basic Info
                  _buildSectionTitle(
                    Icons.info_outline_rounded,
                    'Basic Details',
                  ),
                  SizedBox(height: 12.h),
                  _buildInputField(
                    'Item Name',
                    _nameCtrl,
                    'e.g. Signature Truffle Burger',
                    onChanged: (v) => setState(() {}),
                  ),
                  SizedBox(height: 16.h),

                  // Category Dropdown
                  Text(
                    'Category',
                    style: AppTheme.labelSm.copyWith(color: AppTheme.secondary),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppTheme.surfaceContainerHigh),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: categories.any((c) => c.id == _categoryId)
                            ? _categoryId
                            : null,
                        isExpanded: true,
                        hint: Text(
                          'Select Category',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.secondary,
                          ),
                        ),
                        items: categories.isEmpty
                            ? []
                            : categories.map((c) {
                                return DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                );
                              }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _categoryId = val);
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Price
                  _buildInputField(
                    'Base Price (₹)',
                    _priceCtrl,
                    'e.g. 24.50',
                    type: TextInputType.number,
                  ),
                  SizedBox(height: 32.h),

                  // 4. Description
                  _buildSectionTitle(Icons.subject_rounded, 'Description'),
                  SizedBox(height: 12.h),
                  _buildInputField(
                    'Customer Facing Description',
                    _descCtrl,
                    'A decadent blend of dry-aged beef, melted gruyere...',
                    maxLines: 4,
                  ),
                  SizedBox(height: 32.h),

                  // 5. Visibility
                  _buildSectionTitle(Icons.visibility_outlined, 'Visibility'),
                  SizedBox(height: 12.h),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppTheme.surfaceContainerHigh),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Material(
                      color: AppTheme.surfaceContainerLowest,
                      child: SwitchListTile(
                      title: Text(
                        'Available on Menu',
                        style: AppTheme.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        'Toggle to instantly hide this item from diners',
                        style: AppTheme.bodySm,
                      ),
                      value: _available,
                      activeThumbColor: AppTheme.primary,
                      onChanged: (val) => setState(() => _available = val),
                    ),
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // 6. Recommendation
                  _buildSectionTitle(Icons.auto_awesome_rounded, 'Recommendation'),
                  SizedBox(height: 12.h),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppTheme.surfaceContainerHigh),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Material(
                      color: AppTheme.surfaceContainerLowest,
                      child: SwitchListTile(
                        title: Text(
                          'Eligible for Recommendations',
                          style: AppTheme.bodyMd.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          'Allow the recommendation engine to surface this item to diners',
                          style: AppTheme.bodySm,
                        ),
                        value: _recommendationEnabled,
                        activeThumbColor: AppTheme.primary,
                        onChanged: (val) => setState(() => _recommendationEnabled = val),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  Text(
                    'Recommendation Tags',
                    style: AppTheme.labelSm.copyWith(color: AppTheme.secondary),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Keywords used for recommendation scoring (e.g. chicken, grilled, starter)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      color: AppTheme.secondary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _recTagCtrl,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14.sp),
                          onSubmitted: (_) => _addRecTag(),
                          decoration: InputDecoration(
                            hintText: 'Enter tag and press Add',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: AppTheme.secondary,
                              fontSize: 14.sp,
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
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      ElevatedButton(
                        onPressed: _addRecTag,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.surfaceContainerLow,
                          foregroundColor: AppTheme.primary,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            side: const BorderSide(color: AppTheme.surfaceContainerHigh),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 16.r),
                            SizedBox(width: 4.w),
                            Text(
                              'Add',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_recommendationTags.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: _recommendationTags.map((tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: AppTheme.primaryContainer.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tag,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              GestureDetector(
                                onTap: () => _removeRecTag(tag),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 14.r,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // 7. Relationship CRUD: Recommended With & Don't Recommend With
                  if (widget.item != null && recsState != null) ...[
                    _buildRecommendedWithSection(recsState),
                    _buildDontRecommendWithSection(recsState),
                  ] else ...[
                    _buildNewItemRecommendationNotice(),
                  ],

                  // Bottom padding
                  SizedBox(height: 60.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addRecTag() {
    final text = _recTagCtrl.text.trim().toLowerCase();
    if (text.isNotEmpty && !_recommendationTags.contains(text)) {
      setState(() {
        _recommendationTags.add(text);
        _recTagCtrl.clear();
      });
    }
  }

  void _removeRecTag(String tag) {
    setState(() {
      _recommendationTags.remove(tag);
    });
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20.r, color: AppTheme.onSurface),
        SizedBox(width: 8.w),
        Text(
          title,
          style: AppTheme.titleMd.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    Function(String)? onChanged,
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
          onChanged: onChanged,
          style: GoogleFonts.plusJakartaSans(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: AppTheme.secondary,
              fontSize: 14.sp,
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
              horizontal: 16.w,
              vertical: 14.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewItemRecommendationNotice() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 20.r, color: AppTheme.secondary),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Save this item first to manage "Recommended With" pairings and "Don\'t Recommend With" exclusions.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp,
                color: AppTheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedWithSection(MenuItemRecommendationsState recsState) {
    final activeItems = recsState.activeRecommendedWith;
    final inactiveItems = recsState.inactiveRecommendedWith;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24.h),
        Divider(color: AppTheme.surfaceContainerHigh),
        SizedBox(height: 16.h),
        Row(
          children: [
            Icon(Icons.recommend_rounded, size: 22.r, color: AppTheme.primary),
            SizedBox(width: 8.w),
            Text(
              'Recommended With',
              style: AppTheme.titleSm.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${activeItems.length}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _showAddOrEditRecommendationDialog(),
              icon: Icon(Icons.add_rounded, size: 16.r),
              label: Text(
                'Add',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          'Pair items that will be suggested when diners order or view this dish.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.sp,
            color: AppTheme.secondary,
          ),
        ),
        SizedBox(height: 12.h),
        if (recsState.isLoading && recsState.recommendations.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (recsState.recommendedWith.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppTheme.surfaceContainerHigh),
            ),
            child: Column(
              children: [
                Icon(Icons.auto_awesome_outlined, size: 32.r, color: AppTheme.secondary),
                SizedBox(height: 8.h),
                Text(
                  'No recommendations configured yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Tap "Add" above to select dishes and set recommendation type & priority.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              ...activeItems.map((rec) => _buildRecommendationCard(rec, isExclusion: false)),
              if (inactiveItems.isNotEmpty) ...[
                SizedBox(height: 8.h),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    'Deactivated Recommendations (${inactiveItems.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondary,
                    ),
                  ),
                  children: inactiveItems
                      .map((rec) => _buildRecommendationCard(rec, isExclusion: false))
                      .toList(),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildDontRecommendWithSection(MenuItemRecommendationsState recsState) {
    final activeExclusions = recsState.activeDontRecommendWith;
    final inactiveExclusions = recsState.inactiveDontRecommendWith;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24.h),
        Divider(color: AppTheme.surfaceContainerHigh),
        SizedBox(height: 16.h),
        Row(
          children: [
            Icon(Icons.block_rounded, size: 22.r, color: AppTheme.error),
            SizedBox(width: 8.w),
            Text(
              "Don't Recommend With",
              style: AppTheme.titleSm.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${activeExclusions.length}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.error,
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _showAddExclusionDialog(),
              icon: Icon(Icons.add_rounded, size: 16.r),
              label: Text(
                'Add Exclusion',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceContainerLow,
                foregroundColor: AppTheme.error,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  side: const BorderSide(color: AppTheme.error),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppTheme.error.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, size: 16.r, color: AppTheme.error),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Hard Exclusion: Excluded items are strictly excluded during candidate validation and will never be recommended alongside this dish.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        if (recsState.isLoading && recsState.recommendations.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (recsState.dontRecommendWith.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppTheme.surfaceContainerHigh),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 32.r, color: AppColors.success),
                SizedBox(height: 8.h),
                Text(
                  'No hard exclusions configured',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Other menu items remain eligible for algorithmic pairing.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              ...activeExclusions.map((rec) => _buildRecommendationCard(rec, isExclusion: true)),
              if (inactiveExclusions.isNotEmpty) ...[
                SizedBox(height: 8.h),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    'Deactivated Exclusions (${inactiveExclusions.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondary,
                    ),
                  ),
                  children: inactiveExclusions
                      .map((rec) => _buildRecommendationCard(rec, isExclusion: true))
                      .toList(),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildRecommendationCard(MenuItemRecommendationDto rec, {required bool isExclusion}) {
    final itemName = rec.recommendedItem?.name ??
        'Item ${rec.recommendedMenuItemId.length > 8 ? rec.recommendedMenuItemId.substring(0, 8) : rec.recommendedMenuItemId}';
    final price = rec.recommendedItem != null
        ? '\$${rec.recommendedItem!.basePrice.toStringAsFixed(2)}'
        : '';
    final imageUrl = rec.recommendedItem?.imageUrl;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: rec.isActive ? AppTheme.surfaceContainerHigh : AppTheme.surfaceContainerHighest,
        ),
      ),
      child: Row(
        children: [
          // Item image or icon
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8.r),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.restaurant_rounded, size: 20.r, color: AppTheme.secondary);
                  })
                : Icon(
                    isExclusion ? Icons.block_rounded : Icons.restaurant_rounded,
                    size: 20.r,
                    color: isExclusion ? AppTheme.error : AppTheme.secondary,
                  ),
          ),
          SizedBox(width: 12.w),
          // Info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        itemName,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                          decoration: rec.isActive ? null : TextDecoration.lineThrough,
                          color: rec.isActive ? AppTheme.onSurface : AppTheme.secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (price.isNotEmpty)
                      Text(
                        price,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondary,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  children: [
                    if (isExclusion)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.block_rounded, size: 10.r, color: AppTheme.error),
                            SizedBox(width: 3.w),
                            Text(
                              'Hard Exclusion',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.error,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          rec.typeDisplayName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          rec.priorityDisplayName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: rec.isActive
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppTheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        rec.isActive ? 'Active' : 'Deactivated',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: rec.isActive ? AppColors.success : AppTheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          SizedBox(width: 8.w),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isExclusion && rec.isActive)
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 18.r, color: AppTheme.secondary),
                  tooltip: 'Edit relationship',
                  onPressed: () => _showAddOrEditRecommendationDialog(existing: rec),
                ),
              if (rec.isActive)
                IconButton(
                  icon: Icon(Icons.visibility_off_outlined, size: 18.r, color: AppTheme.secondary),
                  tooltip: 'Deactivate',
                  onPressed: () => _deactivateRecommendation(rec),
                )
              else
                IconButton(
                  icon: Icon(Icons.replay_rounded, size: 18.r, color: AppColors.success),
                  tooltip: 'Reactivate',
                  onPressed: () => _reactivateRecommendation(rec),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddOrEditRecommendationDialog({MenuItemRecommendationDto? existing}) {
    final allItems = ref.read(menuItemsProvider).byId.values.toList();
    final currentRecs = ref.read(itemRecommendationsProvider(widget.item!.id));
    final activeTargetIds = currentRecs.activeRecommendedWith.map((r) => r.recommendedMenuItemId).toSet();

    // Prevent self-reference and active duplicates
    final eligibleItems = allItems.where((i) {
      if (i.id == widget.item!.id) return false;
      if (existing == null && activeTargetIds.contains(i.id)) return false;
      return true;
    }).toList();

    String selectedTargetId = existing?.recommendedMenuItemId ??
        (eligibleItems.isNotEmpty ? eligibleItems.first.id : '');
    String selectedType = existing?.recommendationType ?? 'complementary';
    int selectedPriority = existing?.priority ?? 2;

    const typeOptions = [
      ('complementary', 'Complementary'),
      ('admin_selected', 'Admin Selected'),
      ('complete_meal', 'Complete Meal'),
      ('similar', 'Similar Item'),
      ('popular', 'Popular Pair'),
      ('frequently_bought', 'Frequently Bought'),
    ];

    const priorityOptions = [
      (1, 'Low (1)'),
      (2, 'Normal (2)'),
      (3, 'High (3)'),
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceContainerLowest,
              title: Text(
                existing == null ? 'Add Recommendation' : 'Edit Recommendation',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 420.w),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Target Item Selector (read-only in edit mode)
                      if (existing == null) ...[
                        Text(
                          'Recommended Menu Item',
                          style: AppTheme.labelSm.copyWith(color: AppTheme.secondary),
                        ),
                        SizedBox(height: 6.h),
                        if (eligibleItems.isEmpty)
                          Text(
                            'No eligible items available to recommend.',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.error,
                              fontSize: 13.sp,
                            ),
                          )
                        else
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: AppTheme.surfaceContainerHigh),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedTargetId.isNotEmpty ? selectedTargetId : null,
                                isExpanded: true,
                                items: eligibleItems.map((item) {
                                  return DropdownMenuItem(
                                    value: item.id,
                                    child: Text(
                                      '${item.name} (\$${(item.basePriceAmount / 100.0).toStringAsFixed(2)})',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 14.sp),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => selectedTargetId = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        SizedBox(height: 16.h),
                      ] else ...[
                        Text(
                          'Recommended Menu Item',
                          style: AppTheme.labelSm.copyWith(color: AppTheme.secondary),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          existing.recommendedItem?.name ?? existing.recommendedMenuItemId,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],

                      // Relationship Type Selector
                      Text(
                        'Relationship Type',
                        style: AppTheme.labelSm.copyWith(color: AppTheme.secondary),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: AppTheme.surfaceContainerHigh),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedType,
                            isExpanded: true,
                            items: typeOptions.map((opt) {
                              return DropdownMenuItem(
                                value: opt.$1,
                                child: Text(
                                  opt.$2,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14.sp),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedType = val);
                              }
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Priority Selector
                      Text(
                        'Priority Level',
                        style: AppTheme.labelSm.copyWith(color: AppTheme.secondary),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: priorityOptions.map((opt) {
                          final isSelected = selectedPriority == opt.$1;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: ChoiceChip(
                                label: Text(
                                  opt.$2,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.sp,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : AppTheme.onSurface,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: AppTheme.primary,
                                onSelected: (_) {
                                  setDialogState(() => selectedPriority = opt.$1);
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.secondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedTargetId.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(dialogCtx);
                          final notifier = ref.read(itemRecommendationsProvider(widget.item!.id).notifier);
                          if (existing == null) {
                            final res = await notifier.addRecommendation(
                              recommendedMenuItemId: selectedTargetId,
                              recommendationType: selectedType,
                              priority: selectedPriority,
                            );
                            if (!mounted) return;
                            if (res is Success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Recommendation relationship saved successfully.'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else if (res is Failure) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${(res as Failure).error.message}'),
                                  backgroundColor: AppTheme.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else {
                            final res = await notifier.updateRelationship(
                              recommendationId: existing.id,
                              recommendationType: selectedType,
                              priority: selectedPriority,
                            );
                            if (!mounted) return;
                            if (res is Success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Recommendation relationship updated.'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else if (res is Failure) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${(res as Failure).error.message}'),
                                  backgroundColor: AppTheme.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    existing == null ? 'Add' : 'Save',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddExclusionDialog() {
    final allItems = ref.read(menuItemsProvider).byId.values.toList();
    final currentRecs = ref.read(itemRecommendationsProvider(widget.item!.id));
    final activeExclusionTargetIds = currentRecs.activeDontRecommendWith.map((r) => r.recommendedMenuItemId).toSet();

    // Prevent self-reference and active duplicates
    final eligibleItems = allItems.where((i) {
      if (i.id == widget.item!.id) return false;
      if (activeExclusionTargetIds.contains(i.id)) return false;
      return true;
    }).toList();

    String selectedTargetId = eligibleItems.isNotEmpty ? eligibleItems.first.id : '';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceContainerLowest,
              title: Row(
                children: [
                  Icon(Icons.block_rounded, color: AppTheme.error, size: 22.r),
                  SizedBox(width: 8.w),
                  Text(
                    'Add Hard Exclusion',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 420.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select menu item to strictly exclude from recommendations when this dish is active:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        color: AppTheme.secondary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    if (eligibleItems.isEmpty)
                      Text(
                        'No eligible items available to exclude.',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.error,
                          fontSize: 13.sp,
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: AppTheme.surfaceContainerHigh),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedTargetId.isNotEmpty ? selectedTargetId : null,
                            isExpanded: true,
                            items: eligibleItems.map((item) {
                              return DropdownMenuItem(
                                value: item.id,
                                child: Text(
                                  '${item.name} (\$${(item.basePriceAmount / 100.0).toStringAsFixed(2)})',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14.sp),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedTargetId = val);
                              }
                            },
                          ),
                        ),
                      ),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 16.r, color: AppTheme.error),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Type: dont_recommend (Hard Exclusion). The recommendation engine candidate generator will strictly exclude this item.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.secondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedTargetId.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(dialogCtx);
                          final notifier = ref.read(itemRecommendationsProvider(widget.item!.id).notifier);
                          final res = await notifier.addRecommendation(
                            recommendedMenuItemId: selectedTargetId,
                            recommendationType: 'dont_recommend',
                            priority: 2,
                          );
                          if (!mounted) return;
                          if (res is Success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Hard exclusion configured successfully.'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else if (res is Failure) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${(res as Failure).error.message}'),
                                backgroundColor: AppTheme.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Add Exclusion',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deactivateRecommendation(MenuItemRecommendationDto rec) async {
    final notifier = ref.read(itemRecommendationsProvider(widget.item!.id).notifier);
    final res = await notifier.deactivateRelationship(rec.id);
    if (!mounted) return;
    if (res is Success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Relationship deactivated.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (res is Failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${(res as Failure).error.message}'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _reactivateRecommendation(MenuItemRecommendationDto rec) async {
    final notifier = ref.read(itemRecommendationsProvider(widget.item!.id).notifier);
    final res = await notifier.reactivateRelationship(rec.id);
    if (!mounted) return;
    if (res is Success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Relationship reactivated.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (res is Failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${(res as Failure).error.message}'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

