import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class TaxManagementScreen extends StatefulWidget {
  const TaxManagementScreen({super.key});

  @override
  State<TaxManagementScreen> createState() => _TaxManagementScreenState();
}

class _TaxManagementScreenState extends State<TaxManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _taxRules = [
    {
      'id': 'rule_std',
      'category': 'Burgers & Mains',
      'vatRate': 20.0,
      'serviceChargeRate': 5.0,
      'isExempt': false,
    },
    {
      'id': 'rule_bev',
      'category': 'Beverages',
      'vatRate': 12.5,
      'serviceChargeRate': 5.0,
      'isExempt': false,
    },
    {
      'id': 'rule_exempt',
      'category': 'Water & Basic Bread',
      'vatRate': 0.0,
      'serviceChargeRate': 0.0,
      'isExempt': true,
    },
  ];

  String _selectedCategory = 'Burgers & Mains';
  double _inputAmount = 10.0;
  final _inputCtrl = TextEditingController(text: '10.00');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  double get _currentVatRate {
    final rule = _taxRules.firstWhere((r) => r['category'] == _selectedCategory);
    return rule['vatRate'] as double;
  }

  double get _currentServiceChargeRate {
    final rule = _taxRules.firstWhere((r) => r['category'] == _selectedCategory);
    return rule['serviceChargeRate'] as double;
  }

  double get _calculatedVat => _inputAmount * (_currentVatRate / 100);
  double get _calculatedServiceCharge => _inputAmount * (_currentServiceChargeRate / 100);
  double get _calculatedGross => _inputAmount + _calculatedVat + _calculatedServiceCharge;

  void _editTaxRule(int index) {
    final rule = _taxRules[index];
    final vatCtrl = TextEditingController(text: rule['vatRate'].toString());
    final scCtrl = TextEditingController(text: rule['serviceChargeRate'].toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        title: Text('Edit Tax Rule', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(rule['category'] as String,
                style: GoogleFonts.inter(fontSize: 14.sp, color: AppTheme.secondary)),
            SizedBox(height: 16.h),
            TextField(
              controller: vatCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.jetBrainsMono(),
              decoration: InputDecoration(
                suffixText: '%',
                labelText: 'VAT / Sales Tax',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: scCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.jetBrainsMono(),
              decoration: InputDecoration(
                suffixText: '%',
                labelText: 'Service Charge',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              final newVat = double.tryParse(vatCtrl.text);
              final newSc = double.tryParse(scCtrl.text);
              if (newVat != null && newSc != null) {
                setState(() {
                  _taxRules[index]['vatRate'] = newVat;
                  _taxRules[index]['serviceChargeRate'] = newSc;
                  _taxRules[index]['isExempt'] = (newVat == 0 && newSc == 0);
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        title: Text('Tax Configuration',
            style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryContainer,
          labelColor: AppTheme.primaryContainer,
          unselectedLabelColor: AppTheme.secondary,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.sp),
          tabs: const [
            Tab(text: 'Tax Rules'),
            Tab(text: 'Simulator'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRulesTab(),
          _buildSimulatorTab(),
        ],
      ),
    );
  }

  Widget _buildRulesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jurisdiction-Specific Tax Matrix',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Define tax categories and service charges applied branch-wide.',
            style: GoogleFonts.inter(fontSize: 12.sp, color: AppTheme.secondary),
          ),
          SizedBox(height: 20.h),
          ...List.generate(_taxRules.length, (i) {
            final rule = _taxRules[i];
            final bool exempt = rule['isExempt'] as bool;
            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppTheme.surfaceContainerHigh),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rule['category'] as String,
                          style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8.h),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _taxBadge('VAT: ${rule['vatRate']}%',
                                exempt ? const Color(0xFF64748B) : const Color(0xFFC0272D),
                                exempt ? const Color(0xFFF1F5F9) : const Color(0xFFFEF2F2)),
                            _taxBadge('SC: ${rule['serviceChargeRate']}%',
                                const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
                            if (exempt)
                              _taxBadge('EXEMPT', const Color(0xFF64748B), const Color(0xFFF1F5F9)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Color(0xFFC0272D)),
                    onPressed: () => _editTaxRule(i),
                  ),
                ],
              ),
            ).animate(delay: Duration(milliseconds: 60 * i)).fadeIn(duration: 300.ms).slideY(begin: 0.05);
          }),
        ],
      ),
    );
  }

  Widget _buildSimulatorTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tax Preview Simulator',
            style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4.h),
          Text(
            'Test calculations based on tax regulations.',
            style: GoogleFonts.inter(fontSize: 12.sp, color: AppTheme.secondary),
          ),
          SizedBox(height: 24.h),

          // Form
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppTheme.surfaceContainerHigh),
            ),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Simulation Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  isExpanded: true,
                  items: _taxRules
                      .map((r) => DropdownMenuItem(
                            value: r['category'] as String,
                            child: Text(r['category'] as String, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: _inputCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w600),
                  onChanged: (v) {
                    setState(() => _inputAmount = double.tryParse(v) ?? 0.0);
                  },
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    labelText: 'Simulated net price',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Results Card
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppTheme.surfaceContainerHigh),
            ),
            child: Column(
              children: [
                _simRow('Net price', _inputAmount),
                _simRow('VAT (${_currentVatRate.toStringAsFixed(1)}%)', _calculatedVat),
                _simRow('Service Charge (${_currentServiceChargeRate.toStringAsFixed(1)}%)', _calculatedServiceCharge),
                SizedBox(height: 12.h),
                Divider(height: 1, color: AppTheme.surfaceContainerHigh),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Gross Price',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                    Text(
                      '₹${_calculatedGross.toStringAsFixed(2)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontWeight: FontWeight.w800,
                        fontSize: 20.sp,
                        color: const Color(0xFFC0272D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _taxBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _simRow(String label, double amount) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: GoogleFonts.inter(color: AppTheme.secondary),
                overflow: TextOverflow.ellipsis),
          ),
          SizedBox(width: 8.w),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w600, color: AppTheme.onSurface),
          ),
        ],
      ),
    );
  }
}
