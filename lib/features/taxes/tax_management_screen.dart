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

class _TaxManagementScreenState extends State<TaxManagementScreen> {
  final List<Map<String, dynamic>> _taxRules = [
    {
      'id': 'rule_std',
      'category': 'Burgers & Mains',
      'vatRate': 20.0, // in percentage
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

  // Simulation parameters
  String _selectedCategory = 'Burgers & Mains';
  double _inputAmount = 10.0; // ₹10.00
  final _inputCtrl = TextEditingController(text: '10.00');

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
        title: Text(
          'Edit Tax Rule',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rule['category'] as String,
              style: GoogleFonts.inter(fontSize: 14.sp, color: AppTheme.secondary),
            ),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
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
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        title: Text(
          'Tax Configuration Runtime',
          style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Row(
        children: [
          // Left Pane: Tax rules editor
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jurisdiction-Specific Tax Matrix',
                    style: GoogleFonts.inter(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  Text(
                    'Define tax categories and service charges applied branch-wide.',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: AppTheme.secondary,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  
                  // Rules List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _taxRules.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (ctx, i) {
                      final rule = _taxRules[i];
                      final bool exempt = rule['isExempt'] as bool;
                      return Container(
                        padding: EdgeInsets.all(18.r),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppTheme.surfaceContainerHigh),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rule['category'] as String,
                                  style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4.h),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: exempt ? const Color(0xFFF1F5F9) : const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(4.r),
                                      ),
                                      child: Text(
                                        'VAT: ${rule['vatRate']}%',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 11.sp, 
                                          fontWeight: FontWeight.bold,
                                          color: exempt ? const Color(0xFF64748B) : const Color(0xFFC0272D),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0FDF4),
                                        borderRadius: BorderRadius.circular(4.r),
                                      ),
                                      child: Text(
                                        'Service Charge: ${rule['serviceChargeRate']}%',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 11.sp, 
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF16A34A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Color(0xFFC0272D)),
                              onPressed: () => _editTaxRule(i),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Right Pane: Tax preview simulator
          Container(
            width: 360.w,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              border: Border(left: BorderSide(color: AppTheme.surfaceContainerHigh)),
            ),
            padding: EdgeInsets.all(24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tax preview simulator',
                  style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Test calculations based on tax regulations.',
                  style: GoogleFonts.inter(fontSize: 12.sp, color: AppTheme.secondary),
                ),
                SizedBox(height: 24.h),
                
                // Form parameters
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Simulation Category'),
                  isExpanded: true,
                  items: _taxRules
                      .map((r) => DropdownMenuItem(
                            value: r['category'] as String,
                            child: Text(
                              r['category'] as String,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                    setState(() {
                      _inputAmount = double.tryParse(v) ?? 0.0;
                    });
                  },
                  decoration: const InputDecoration(
                    prefixText: '₹ ',
                    labelText: 'Simulated net price',
                  ),
                ),
                
                SizedBox(height: 32.h),
                Divider(height: 1, color: AppTheme.surfaceContainerHigh),
                SizedBox(height: 20.h),
                
                // Live preview projection list
                _simRow('Net price', _inputAmount),
                _simRow('VAT (${_currentVatRate.toStringAsFixed(1)}%)', _calculatedVat),
                _simRow('Service Charge (${_currentServiceChargeRate.toStringAsFixed(1)}%)', _calculatedServiceCharge),
                SizedBox(height: 12.h),
                Divider(height: 1, color: AppTheme.surfaceContainerHigh),
                SizedBox(height: 12.h),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Gross Price',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16.sp),
                    ),
                    Text(
                      '₹${_calculatedGross.toStringAsFixed(2)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontWeight: FontWeight.w800,
                        fontSize: 18.sp,
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

  Widget _simRow(String label, double amount) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(color: AppTheme.secondary),
              overflow: TextOverflow.ellipsis,
            ),
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
