import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import 'runtime_ready_provider.dart';

class RuntimeReadyGate extends ConsumerWidget {
  final Widget child;

  const RuntimeReadyGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReady = ref.watch(runtimeReadyProvider);
    
    // Graceful wait if context is still hydrating
    if (!isReady) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryContainer),
        ),
      );
    }
    
    return child;
  }
}
