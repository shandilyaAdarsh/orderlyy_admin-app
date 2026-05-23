// lib/features/customer/presentation/widgets/customer_cart_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../state/customer_providers.dart';
import 'customer_components.dart';

class CustomerCartSheet extends ConsumerStatefulWidget {
  const CustomerCartSheet({super.key});

  @override
  ConsumerState<CustomerCartSheet> createState() => _CustomerCartSheetState();
}

class _CustomerCartSheetState extends ConsumerState<CustomerCartSheet> {
  bool _isCheckingOut = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(customerSessionProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (session == null || session.cart.isEmpty) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_basket_outlined, size: 64, color: AppColors.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items from the menu to start your order.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your Cart',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Cart Items List
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: session.cart.length,
              itemBuilder: (context, index) {
                final cartItem = session.cart[index];
                return Padding(
                  key: ValueKey(cartItem.id),
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cartItem.item.name,
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (cartItem.selectedModifiers.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                cartItem.selectedModifiers.map((m) => m.name).join(', '),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              cartItem.totalPrice.formatted,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Quantity controls
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 22),
                            onPressed: () {
                              ref.read(customerSessionProvider.notifier).updateQuantity(cartItem.id, -1);
                            },
                          ),
                          Text(
                            '${cartItem.quantity}',
                            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 22),
                            onPressed: () {
                              ref.read(customerSessionProvider.notifier).updateQuantity(cartItem.id, 1);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 24),
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                session.subtotal.formatted,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Checkout Button
          AppButton(
            label: 'Send to Kitchen • ${session.subtotal.formatted}',
            isLoading: _isCheckingOut,
            onPressed: () async {
              setState(() => _isCheckingOut = true);
              try {
                await ref.read(customerSessionProvider.notifier).checkout();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order sent to the kitchen successfully!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Checkout failed: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isCheckingOut = false);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
