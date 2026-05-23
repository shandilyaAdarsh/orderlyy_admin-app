import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/auth/mock_auth_provider.dart';
import '../../core/theme/app_theme.dart';

// Steps in order — must match what the backend stores in steps_completed
const _onboardingSteps = ['profile', 'menu', 'tables'];

class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  ConsumerState<OnboardingWizardScreen> createState() =>
      _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState
    extends ConsumerState<OnboardingWizardScreen> {
  int _currentStepIndex = 0;
  bool _isSaving = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initStep();
  }

  /// Resume to the first incomplete step
  void _initStep() {
    final ctx = ref.read(appContextProvider);
    if (ctx == null) return;

    if (ctx.onboarding.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/admin/dashboard');
      });
      return;
    }

    final done = ctx.onboarding.stepsCompleted;
    for (int i = 0; i < _onboardingSteps.length; i++) {
      if (!done.contains(_onboardingSteps[i])) {
        _currentStepIndex = i;
        return;
      }
    }
    // All steps already done — navigate to dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/admin/dashboard');
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  String get _tenantId => ref.read(appContextProvider)?.tenant.id ?? '';

  Future<void> _completeCurrentStep() async {
    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    try {
      final stepName = _onboardingSteps[_currentStepIndex];
      final isLastStep = _currentStepIndex == _onboardingSteps.length - 1;

      await ref
          .read(appContextProvider.notifier)
          .completeOnboardingStep(_tenantId, stepName, isLastStep);

      // Get updated ctx from provider
      final updatedCtx = ref.read(appContextProvider);

      if (isLastStep) {
        if (mounted) context.go('/admin/dashboard');
      } else {
        // Advance to the next incomplete step
        if (mounted) {
          setState(() {
            if (updatedCtx == null) {
              context.go('/role-select');
              return;
            }
            final done = updatedCtx.onboarding.stepsCompleted;
            for (int i = 0; i < _onboardingSteps.length; i++) {
              if (!done.contains(_onboardingSteps[i])) {
                _currentStepIndex = i;
                return;
              }
            }
          });
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctx = ref.watch(appContextProvider);
    final tenantName = ctx?.tenant.name ?? 'Your Restaurant';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Orderlli',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryContainer,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    tenantName,
                    style: GoogleFonts.inter(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 16.h),
                  // Progress indicator
                  Row(
                    children: List.generate(_onboardingSteps.length, (i) {
                      final done =
                          ctx?.onboarding.stepsCompleted.contains(
                            _onboardingSteps[i],
                          ) ??
                          false;
                      final active = i == _currentStepIndex;
                      return Expanded(
                        child: Container(
                          height: 4.h,
                          margin: EdgeInsets.only(right: i < 2 ? 6.w : 0),
                          decoration: BoxDecoration(
                            color: done
                                ? AppTheme.primaryContainer
                                : active
                                ? AppTheme.primaryContainer.withValues(
                                    alpha: 0.4,
                                  )
                                : AppTheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Step ${_currentStepIndex + 1} of ${_onboardingSteps.length}',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1.h, color: AppTheme.surfaceContainerHigh),

            // ── Step Content ───────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
                child: _buildStep(_currentStepIndex),
              ),
            ),

            // ── Error + CTA ────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 32.h),
              child: Column(
                children: [
                  if (_errorMessage.isNotEmpty) ...[
                    Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: const Color(0xFFEF4444),
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _completeCurrentStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryContainer,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
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
                              _currentStepIndex == _onboardingSteps.length - 1
                                  ? 'Complete Setup'
                                  : 'Continue',
                              style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int index) {
    switch (index) {
      case 0:
        return _buildProfileStep();
      case 1:
        return _buildMenuStep();
      case 2:
        return _buildTablesStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildProfileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          Icons.qr_code_2_rounded,
          'Your QR Menu Is Ready',
          'Guests can scan and view your live menu instantly',
        ),
        SizedBox(height: 24.h),
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 72.r,
                    height: 72.r,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.qr_code_rounded,
                      size: 44.r,
                      color: AppTheme.primaryContainer,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Text(
                      'Place this QR at each table so guests can browse and order in seconds.',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: AppTheme.secondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                'Tip: Print one table card and duplicate it for all tables.',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          Icons.kitchen_rounded,
          'Real-Time Kitchen Display',
          'KDS receives orders instantly as guests place them',
        ),
        SizedBox(height: 24.h),
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 40.r,
                color: AppTheme.primaryContainer,
              ),
              SizedBox(height: 12.h),
              Text(
                'New tickets appear in KDS automatically. Your team can track pending, preparing, and ready items in one flow.',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppTheme.secondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'No extra setup needed for your first run.',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTablesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          Icons.table_restaurant_rounded,
          'Your Tables Are Set',
          'Default tables are ready and editable from dashboard',
        ),
        SizedBox(height: 24.h),
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: List.generate(13, (i) {
                  final label = 'T${(i + 1).toString().padLeft(2, '0')}';
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppTheme.surfaceContainerHigh),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 12.h),
              Text(
                'These tables are pre-created for launch and can be renamed later.',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppTheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepHeader(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 48.r,
          height: 48.r,
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: AppTheme.primaryContainer, size: 26.r),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: AppTheme.secondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
