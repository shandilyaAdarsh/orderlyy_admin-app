// lib/features/orders/presentation/widgets/modifier_selector_sheet.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/menu_product.dart';

class ModifierGroup {
  final String id;
  final String name;
  final int minSelections;
  final int maxSelections;
  final List<ModifierOption> options;
  final bool isRequired;

  const ModifierGroup({
    required this.id,
    required this.name,
    required this.minSelections,
    required this.maxSelections,
    required this.options,
    required this.isRequired,
  });

  bool validate(List<ModifierOption> selected) {
    final count = selected.where((opt) => options.contains(opt)).length;
    return count >= minSelections && count <= maxSelections;
  }
}

class ModifierSelectorSheet extends StatefulWidget {
  final MenuProduct product;
  final Function(List<ModifierOption> selected) onConfirm;

  const ModifierSelectorSheet({
    super.key,
    required this.product,
    required this.onConfirm,
  });

  @override
  State<ModifierSelectorSheet> createState() => _ModifierSelectorSheetState();
}

class _ModifierSelectorSheetState extends State<ModifierSelectorSheet> {
  final List<ModifierOption> _selected = [];

  List<ModifierGroup> _getModifierGroups() {
    final available = widget.product.availableModifiers;
    if (widget.product.id == 'prod_burger') {
      return [
        ModifierGroup(
          id: 'bg_cheeses',
          name: 'Choose Cheese (Min 0, Max 2)',
          minSelections: 0,
          maxSelections: 2,
          isRequired: false,
          options: available.where((o) => o.id == 'mod_cheddar').toList(),
        ),
        ModifierGroup(
          id: 'bg_addons',
          name: 'Choose Add-ons (Min 0, Max 2)',
          minSelections: 0,
          maxSelections: 2,
          isRequired: false,
          options: available.where((o) => o.id == 'mod_bacon' || o.id == 'mod_avocado').toList(),
        ),
        ModifierGroup(
          id: 'bg_buns',
          name: 'Choose Bun (Min 0, Max 1)',
          minSelections: 0,
          maxSelections: 1,
          isRequired: false,
          options: available.where((o) => o.id == 'mod_gf_bun').toList(),
        ),
      ];
    } else if (widget.product.id == 'prod_chicken') {
      return [
        ModifierGroup(
          id: 'ch_cheese',
          name: 'Cheese Option (Min 0, Max 1)',
          minSelections: 0,
          maxSelections: 1,
          isRequired: false,
          options: available.where((o) => o.id == 'mod_swiss').toList(),
        ),
        ModifierGroup(
          id: 'ch_sauces',
          name: 'Choose Sauces (Min 1, Max 2)',
          minSelections: 1,
          maxSelections: 2,
          isRequired: true,
          options: available.where((o) => o.id == 'mod_spicy_mayo' || o.id == 'mod_jalapenos').toList(),
        ),
      ];
    } else if (widget.product.id == 'prod_salad') {
      return [
        ModifierGroup(
          id: 'sd_protein',
          name: 'Proteins (Min 0, Max 1)',
          minSelections: 0,
          maxSelections: 1,
          isRequired: false,
          options: available.where((o) => o.id == 'mod_chicken_breast').toList(),
        ),
        ModifierGroup(
          id: 'sd_dressings',
          name: 'Dressings (Min 1, Max 1)',
          minSelections: 1,
          maxSelections: 1,
          isRequired: true,
          options: available.where((o) => o.id == 'mod_dressing').toList(),
        ),
      ];
    } else if (widget.product.id == 'prod_fries') {
      return [
        ModifierGroup(
          id: 'fr_flavors',
          name: 'Flavors (Min 1, Max 2)',
          minSelections: 1,
          maxSelections: 2,
          isRequired: true,
          options: available.where((o) => o.id == 'mod_parmesan' || o.id == 'mod_truffle').toList(),
        ),
      ];
    } else {
      return [
        ModifierGroup(
          id: 'catch_all',
          name: 'Options (Min 0, Max 5)',
          minSelections: 0,
          maxSelections: 5,
          isRequired: false,
          options: available,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    var totalPrice = widget.product.price;
    for (final mod in _selected) {
      totalPrice = totalPrice + mod.price;
    }

    final groups = _getModifierGroups();
    final allGroupsValid = groups.every((g) => g.validate(_selected));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.product.name,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Customize item options',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.product.availableModifiers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'No custom options available for this item.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: groups.length,
                itemBuilder: (context, gIndex) {
                  final group = groups[gIndex];
                  final isGroupValid = group.validate(_selected);

                  // Count selected options in this group
                  final groupSelectedCount = _selected.where((opt) => group.options.contains(opt)).length;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              group.name,
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (!isGroupValid)
                              const Text(
                                'Selection required',
                                style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.bold),
                              )
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...group.options.map((modifier) {
                          final isChecked = _selected.contains(modifier);
                          return CheckboxListTile(
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                            title: Text(modifier.name, style: theme.textTheme.bodyLarge),
                            subtitle: Text(
                              modifier.price.amountInCents == 0 ? 'Free' : '+ ${modifier.price.formatted}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: modifier.price.amountInCents == 0 ? AppColors.success : AppColors.primary,
                              ),
                            ),
                            value: isChecked,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  // Validate max selections before adding
                                  if (groupSelectedCount < group.maxSelections) {
                                    _selected.add(modifier);
                                  } else {
                                    // If max selections reached and max is 1, toggle selection (single choice behavior)
                                    if (group.maxSelections == 1) {
                                      _selected.removeWhere((opt) => group.options.contains(opt));
                                      _selected.add(modifier);
                                    }
                                  }
                                } else {
                                  _selected.remove(modifier);
                                }
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Price',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    totalPrice.formatted,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: allGroupsValid ? AppColors.primary : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: allGroupsValid
                    ? () {
                        widget.onConfirm(_selected);
                        Navigator.pop(context);
                      }
                    : null,
                child: const Text('Add to Order', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
