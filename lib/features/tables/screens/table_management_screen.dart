import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/table_model.dart';
import '../providers/table_provider.dart';

class TableManagementScreen extends ConsumerWidget {
  const TableManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tables')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add table'),
        onPressed: () => _showAddDialog(context, ref),
      ),
      body: tablesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tables) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tables.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (ctx, i) => _TableTile(table: tables[i]),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final numCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add table'),
        content: TextField(
          controller: numCtrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Table number',
            hintText: 'e.g. 7',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (numCtrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              final created = await ref
                  .read(tablesProvider.notifier)
                  .addTable(numCtrl.text.trim(), null);
              // Show QR immediately after creation
              if (context.mounted) _showQrDialog(context, created);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showQrDialog(BuildContext context, RestaurantTable table) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Table ${table.tableNumber} — print QR'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          QrImageView(data: table.qrUrl, size: 200), // qr_flutter package
          const SizedBox(height: 8),
          Text(table.qrUrl,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          const Text(
            'This QR never expires. Print once.',
            style: TextStyle(fontSize: 12, color: Colors.green),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

// ── tile ──────────────────────────────────────────────────────────
class _TableTile extends ConsumerWidget {
  const _TableTile({required this.table});
  final RestaurantTable table;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.table_restaurant_outlined),
      title: Text('Table ${table.tableNumber}'),
      subtitle: Text(table.id, style: const TextStyle(fontSize: 11)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          icon: const Icon(Icons.qr_code),
          tooltip: 'Show QR',
          onPressed: () => _showQrDialog(context, table),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Remove table',
          color: Colors.red,
          onPressed: () => _confirmRemove(context, ref),
        ),
      ]),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove Table ${table.tableNumber}?'),
        content: const Text(
          'Customers scanning the old QR will see a "table not available" message. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(tablesProvider.notifier)
                  .removeTable(table.id);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showQrDialog(BuildContext context, RestaurantTable table) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Table ${table.tableNumber}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          QrImageView(data: table.qrUrl, size: 200),
          const SizedBox(height: 8),
          SelectableText(table.qrUrl,
              style: const TextStyle(fontSize: 11)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
