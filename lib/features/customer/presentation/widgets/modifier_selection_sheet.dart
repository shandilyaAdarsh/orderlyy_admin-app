// lib/features/customer/presentation/widgets/modifier_selection_sheet.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/money.dart';
import '../../../menu/domain/entities/menu_snapshot.dart';
import 'customer_components.dart';

class ModifierSelectionSheet extends StatefulWidget {
  final MenuItem item;
  final List<ModifierGroup> modifierGroups;
  final void Function(int quantity, List<ModifierOption> selectedOptions) onConfirm;

  const ModifierSelectionSheet({
    super.key,
    required this.item,
    required this.modifierGroups,
    required this.onConfirm,
  });

  @override
  State<ModifierSelectionSheet> createState() => _ModifierSelectionSheetState();
}

class _ModifierSelectionSheetState extends State<ModifierSelectionSheet> {
  int _quantity = 1;
  final Map<String, List<ModifierOption>> _selectedOptions = {};

  @override
  void initState() {
    super.initState();
    // Pre-select first option for required/single-select groups
    for (final group in widget.modifierGroups) {
      if (_isSingleSelect(group)) {
        if (group.options.isNotEmpty) {
          _selectedOptions[group.id] = [group.options.first];
        }
      } else {
        _selectedOptions[group.id] = [];
      }
    }
  }

  bool _isSingleSelect(ModifierGroup group) {
    final name = group.name.toLowerCase();
    return name.contains('size') || name.contains('crust') || name.contains('base') || name.contains('type');
  }

  int _getMinSelect(ModifierGroup group) {
    return _isSingleSelect(group) ? 1 : 0;
  }

  int _getMaxSelect(ModifierGroup group) {
    return _isSingleSelect(group) ? 1 : 5; // Allow up to 5 toppings/addons
  }

  void _toggleOption(ModifierGroup group, ModifierOption option) {
    final groupId = group.id;
    final isSingle = _isSingleSelect(group);
    final maxSelect = _getMaxSelect(group);
    final currentList = List<ModifierOption>.from(_selectedOptions[groupId] ?? []);

    setState(() {
      if (isSingle) {
        _selectedOptions[groupId] = [option];
      } else {
        if (currentList.contains(option)) {
          currentList.remove(option);
        } else {
          if (currentList.length < maxSelect) {
            currentList.add(option);
          } else {
            // Show alert/snack bar for limit
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You can select a maximum of $maxSelect options in ${group.name}'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        }
        _selectedOptions[groupId] = currentList;
      }
    });
  }

  bool _validateSelections() {
    for (final group in widget.modifierGroups) {
      final selectedCount = _selectedOptions[group.id]?.length ?? 0;
      final min = _getMinSelect(group);
      if (selectedCount < min) {
        return false;
      }
    }
    return true;
  }

  Money _calculateTotalPrice() {
    var unitPrice = widget.item.price;
    _selectedOptions.forEach((_, options) {
      for (final opt in options) {
        unitPrice = unitPrice + opt.price;
      }
    });
    return Money(
      amountInCents: unitPrice.amountInCents * _quantity,
      currency: unitPrice.currency,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isValid = _validateSelections();
    final totalPrice = _calculateTotalPrice();

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
          // Title & Description
          Text(
            widget.item.name,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (widget.item.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.item.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Modifier groups list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.modifierGroups.length,
              itemBuilder: (context, index) {
                final group = widget.modifierGroups[index];
                final isSingle = _isSingleSelect(group);
                final minSelect = _getMinSelect(group);
                final maxSelect = _getMaxSelect(group);
                final selectedList = _selectedOptions[group.id] ?? [];

                return Padding(
                  key: ValueKey(group.id),
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            group.name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            isSingle
                                ? 'Choose exactly 1 (Required)'
                                : 'Choose up to $maxSelect (Optional)',
                            style: TextStyle(
                              color: minSelect > 0 ? AppColors.primary : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Options list
                      ...group.options.map((opt) {
                        final isSelected = selectedList.contains(opt);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(opt.name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (opt.price.amountInCents > 0)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: Text(
                                    '+${opt.price.formatted}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                               isSingle
                                  ? // ignore: deprecated_member_use
                                    Radio<ModifierOption>(
                                      value: opt,
                                      // ignore: deprecated_member_use
                                      groupValue: isSelected ? opt : null,
                                      // ignore: deprecated_member_use
                                      onChanged: (_) => _toggleOption(group, opt),
                                      activeColor: AppColors.primary,
                                    )
                                  : Checkbox(
                                      value: isSelected,
                                      onChanged: (_) => _toggleOption(group, opt),
                                      activeColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(),
          const SizedBox(height: 10),
          // Quantity selector & Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Quantity Counter
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    ),
                    Text(
                      '$_quantity',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ),
              // Add button
              SizedBox(
                width: 180,
                child: AppButton(
                  label: 'Add • ${totalPrice.formatted}',
                  onPressed: isValid
                      ? () {
                          final flatSelected = <ModifierOption>[];
                          _selectedOptions.forEach((_, options) {
                            flatSelected.addAll(options);
                          });
                          widget.onConfirm(_quantity, flatSelected);
                          Navigator.pop(context);
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
