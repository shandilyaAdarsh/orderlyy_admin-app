import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/auth_provider.dart';

// ——————————————————————————————————————————————————————————————
const _kPrimary = Color(0xFFC0272D);
const _kCategories = [
  'ALL',
  'STARTERS',
  'MAINS',
  'SIDES',
  'DESSERTS',
  'BEVERAGES',
];

// ——————————————————————————————————————————————————————————————
class _MenuItem {
  final String id;
  final String? tenantId;
  final String name;
  final String category;
  final double price;
  final String? imageUrl;
  final bool isAvailable;

  const _MenuItem({
    required this.id,
    this.tenantId,
    required this.name,
    required this.category,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
  });

  _MenuItem copyWith({bool? isAvailable}) => _MenuItem(
    id: id,
    name: name,
    category: category,
    price: price,
    imageUrl: imageUrl,
    isAvailable: isAvailable ?? this.isAvailable,
  );

  factory _MenuItem.fromMap(Map<String, dynamic> m) => _MenuItem(
    id: m['id'] as String,
    tenantId: m['tenant_id'] as String?,
    name: m['name'] as String? ?? '',
    category: (m['category'] as String? ?? 'MAINS').toUpperCase(),
    price: (m['price'] as num? ?? 0).toDouble(),
    imageUrl: m['image_url'] as String?,
    isAvailable: m['is_available'] as bool? ?? true,
  );
}

// â”€â”€ Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() =>
      _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  List<_MenuItem> _items = [];
  bool _isLoading = true;
  int _catIndex = 0;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // â”€â”€ Fetch helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<String?> _getTenantId() async {
    // Prefer staffSessionProvider value if available
    final session = ref.read(staffSessionProvider);
    if (session != null) return session.tenantId;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    // Try profile (may fail with RLS)
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('tenant_id')
          .eq('id', user.id)
          .maybeSingle();
      if (profile is Map<String, dynamic> && profile['tenant_id'] != null) {
        return profile['tenant_id'] as String;
      }
    } catch (_) {}

    // Fallback: try resolving tenant id from saved tenant slug (remember-me)
    try {
      final prefs = await SharedPreferences.getInstance();
      final slug = prefs.getString('tenant_slug');
      if (slug != null && slug.isNotEmpty) {
        final t = await Supabase.instance.client
            .from('tenants')
            .select('id')
            .eq('slug', slug)
            .maybeSingle();
        if (t is Map<String, dynamic> && t['id'] != null) {
          return t['id'] as String;
        }
      }
    } catch (_) {}

    return null;
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final tenantId = await _getTenantId();
      if (tenantId == null) {
        // Show demo data if no tenant
        setState(() {
          _items = _demoItems;
          _isLoading = false;
        });
        return;
      }
      // Fetch tenant-specific items plus any global items (tenant_id IS NULL).
      // Use PostgREST OR filter and then dedupe by name, preferring tenant items.
      final data = await Supabase.instance.client
          .from('menu_items')
          .select()
          .or('tenant_id.eq.$tenantId,tenant_id.is.null')
          .order('sort_order');

      // Deduplicate by name (case-insensitive): prefer rows owned by this tenant.
      final raw = data as List;
      final Map<String, Map<String, dynamic>> pick = {};
      for (final row in raw) {
        final nameKey = (row['name'] ?? '').toString().toLowerCase();
        if (nameKey.isEmpty) continue;
        final existing = pick[nameKey];
        if (existing == null) {
          pick[nameKey] = Map<String, dynamic>.from(row);
        } else {
          // prefer tenant-owned row
          if (row['tenant_id'] == tenantId &&
              existing['tenant_id'] != tenantId) {
            pick[nameKey] = Map<String, dynamic>.from(row);
          }
        }
      }

      setState(() {
        _items = pick.values.map((m) => _MenuItem.fromMap(m)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _items = _demoItems;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAvailability(_MenuItem item) async {
    // Prevent toggling template/global items (tenant_id == null)
    if (item.tenantId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Copy this item to your menu before toggling availability.',
            ),
          ),
        );
      }
      return;
    }

    final newVal = !item.isAvailable;
    // Optimistic update
    setState(() {
      _items = _items.map((it) {
        return it.id == item.id ? it.copyWith(isAvailable: newVal) : it;
      }).toList();
    });
    try {
      await Supabase.instance.client
          .from('menu_items')
          .update({'is_available': newVal})
          .eq('id', item.id);
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update availability: $msg'),
            backgroundColor: _kPrimary,
          ),
        );
      }
      // Revert on failure
      setState(() {
        _items = _items.map((it) {
          return it.id == item.id ? it.copyWith(isAvailable: !newVal) : it;
        }).toList();
      });
    }
  }

  List<_MenuItem> get _filtered {
    var list = _items;
    if (_catIndex > 0) {
      list = list.where((i) => i.category == _kCategories[_catIndex]).toList();
    }
    if (_search.isNotEmpty) {
      list = list
          .where((i) => i.name.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // â”€â”€ App Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                      '${_items.length}',
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
                  icon: Icon(Icons.add_rounded, color: _kPrimary, size: 24.r),
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
                          contentPadding: EdgeInsets.symmetric(vertical: 0.h),
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

            // ———————————————————————————————————————————————————————— Body ————————————————————————————————————————————————————————
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: _kPrimary),
                ),
              )
            else if (_filtered.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.restaurant_menu_outlined,
                        size: 64.r,
                        color: const Color(0xFFCBD5E1).withValues(alpha: 0.6),
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
                          item: _filtered[i],
                          onToggle: () => _toggleAvailability(_filtered[i]),
                          onTap: () => _showEditSheet(context, _filtered[i]),
                        )
                        .animate(delay: Duration(milliseconds: 40 * i))
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.1, curve: Curves.easeOut);
                  }, childCount: _filtered.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Edit / Add sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showEditSheet(BuildContext context, _MenuItem? item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MenuItemSheet(item: item, onSaved: _load),
    );
  }
}

// â”€â”€ Menu Item Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _MenuItemCard extends StatelessWidget {
  final _MenuItem item;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _MenuItemCard({
    required this.item,
    required this.onToggle,
    required this.onTap,
  });

  Color get _catColor {
    return switch (item.category) {
      'STARTERS' => const Color(0xFFF59E0B),
      'MAINS' => _kPrimary,
      'DESSERTS' => const Color(0xFFEC4899),
      'BEVERAGES' => const Color(0xFF3B82F6),
      'SIDES' => const Color(0xFF10B981),
      _ => const Color(0xFF64748B),
    };
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
              // Category dot
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
                            item.category,
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: _catColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Toggle
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

// â”€â”€ Add / Edit Bottom Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _MenuItemSheet extends ConsumerStatefulWidget {
  final _MenuItem? item;
  final VoidCallback onSaved;
  const _MenuItemSheet({this.item, required this.onSaved});

  @override
  ConsumerState<_MenuItemSheet> createState() => _MenuItemSheetState();
}

class _MenuItemSheetState extends ConsumerState<_MenuItemSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _customCatCtrl = TextEditingController();
  String _category = 'MAINS';
  bool _available = true;
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
    _category = item?.category ?? 'MAINS';
    _available = item?.isAvailable ?? true;
    _currentImageUrl = item?.imageUrl;

    if (!_kCategories.contains(_category)) {
      _useCustomCat = true;
      _customCatCtrl.text = _category;
      _category = 'OTHER';
    }
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
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<String?> _getTenantId() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('tenant_id')
          .eq('id', user.id)
          .single();
      return profile['tenant_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _uploadImage(String tenantId) async {
    if (_pickedImage == null) return _currentImageUrl;

    try {
      final file = File(_pickedImage!.path);
      final fileExt = _pickedImage!.name.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$tenantId/$fileName';

      await Supabase.instance.client.storage
          .from('menu-images')
          .upload(filePath, file);

      final url = Supabase.instance.client.storage
          .from('menu-images')
          .getPublicUrl(filePath);

      return url;
    } catch (e) {
      debugPrint('Upload error: $e');
      return _currentImageUrl;
    }
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
      // Prefer staffSessionProvider; fall back to querying profiles if needed
      String? tenantId = ref.read(staffSessionProvider)?.tenantId;
      tenantId ??= await _getTenantId();
      if (tenantId == null) {
        throw 'Session expired or tenant not found. Please log in again.';
      }

      final imageUrl = await _uploadImage(tenantId);
      final category = _useCustomCat
          ? _customCatCtrl.text.trim().toUpperCase()
          : _category;

      final data = {
        'name': name,
        'price': double.tryParse(_priceCtrl.text) ?? 0,
        'category': category.isEmpty ? 'MAINS' : category,
        'image_url': imageUrl,
        'is_available': _available,
        'tenant_id': tenantId,
      };

      if (widget.item == null) {
        await Supabase.instance.client.from('menu_items').insert(data);
      } else {
        await Supabase.instance.client
            .from('menu_items')
            .update(data)
            .eq('id', widget.item!.id);
      }
      if (mounted) Navigator.pop(context);
      widget.onSaved();
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
      await Supabase.instance.client
          .from('menu_items')
          .delete()
          .eq('id', widget.item!.id);
      if (mounted) Navigator.pop(context);
      widget.onSaved();
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

// â”€â”€ Demo data (shown when no tenant or Supabase error) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const _demoItems = [
  _MenuItem(
    id: '1',
    name: 'Butter Chicken',
    category: 'MAINS',
    price: 380,
    isAvailable: true,
  ),
  _MenuItem(
    id: '2',
    name: 'Paneer Tikka',
    category: 'STARTERS',
    price: 280,
    isAvailable: true,
  ),
  _MenuItem(
    id: '3',
    name: 'Garlic Naan',
    category: 'SIDES',
    price: 60,
    isAvailable: true,
  ),
  _MenuItem(
    id: '4',
    name: 'Mango Lassi',
    category: 'BEVERAGES',
    price: 120,
    isAvailable: false,
  ),
  _MenuItem(
    id: '5',
    name: 'Gulab Jamun',
    category: 'DESSERTS',
    price: 160,
    isAvailable: true,
  ),
  _MenuItem(
    id: '6',
    name: 'Dal Makhani',
    category: 'MAINS',
    price: 260,
    isAvailable: true,
  ),
  _MenuItem(
    id: '7',
    name: 'Chicken 65',
    category: 'STARTERS',
    price: 320,
    isAvailable: true,
  ),
  _MenuItem(
    id: '8',
    name: 'Masala Papad',
    category: 'SIDES',
    price: 80,
    isAvailable: true,
  ),
];
