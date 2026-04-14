import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/address_book_entry.dart';
import '../models/asset_id.dart';
import '../providers/address_book_provider.dart';
import '../widgets/skeleton_shimmer.dart';

class AddressBookScreen extends ConsumerStatefulWidget {
  const AddressBookScreen({super.key});

  @override
  ConsumerState<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends ConsumerState<AddressBookScreen> {
  final _searchCtrl = TextEditingController();

  static String _initialTickerLetter(String ticker) {
    final t = ticker.trim();
    if (t.isEmpty) return '?';
    return t.substring(0, 1).toUpperCase();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static int _compareEntries(AddressBookEntry a, AddressBookEntry b) {
    final la = a.label.toLowerCase();
    final lb = b.label.toLowerCase();
    final c = la.compareTo(lb);
    if (c != 0) return c;
    return a.address.toLowerCase().compareTo(b.address.toLowerCase());
  }

  List<AddressBookEntry> _filteredSorted(List<AddressBookEntry> entries) {
    final q = _searchCtrl.text.trim().toLowerCase();
    var list = List<AddressBookEntry>.from(entries);
    if (q.isNotEmpty) {
      list = list
          .where((e) =>
              e.label.toLowerCase().contains(q) ||
              e.address.toLowerCase().contains(q))
          .toList();
    }
    list.sort(_compareEntries);
    return list;
  }

  AssetId? _assetForEntry(AddressBookEntry e) {
    for (final a in AssetId.values) {
      if (a.name == e.assetKey) return a;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(addressBookProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Address book'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditDialog(context, ref, null),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name or address',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1A2A3E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: async.when(
              loading: () => ListView(
                padding: const EdgeInsets.only(top: 8),
                children: List.generate(
                  8,
                  (_) => const SkeletonListTile(),
                ),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Save trusted addresses for faster, safer sends. '
                        'Tap Add to create your first contact.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                }
                final shown = _filteredSorted(entries);
                if (shown.isEmpty) {
                  return Center(
                    child: Text(
                      'No contacts match “${_searchCtrl.text.trim()}”.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  itemCount: shown.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final e = shown[i];
                    final asset = _assetForEntry(e);
                    return Dismissible(
                      key: ValueKey(e.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red.withValues(alpha: 0.25),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                      ),
                      onDismissed: (_) {
                        ref.read(addressBookProvider.notifier).remove(e.id);
                      },
                      child: Material(
                        color: const Color(0xFF1A2A3E),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: e.address));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Address copied'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: (asset?.color ??
                                          Colors.blueGrey)
                                      .withValues(alpha: 0.2),
                                  child: Text(
                                    _initialTickerLetter(
                                        asset?.ticker ?? e.assetKey),
                                    style: TextStyle(
                                      color: asset?.color ?? Colors.blueGrey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        e.address,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        asset?.ticker ?? e.assetKey,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert,
                                      color: Colors.white54),
                                  onSelected: (action) async {
                                    if (action == 'edit') {
                                      await _showAddOrEditDialog(
                                          context, ref, e);
                                    } else if (action == 'copy') {
                                      await Clipboard.setData(
                                          ClipboardData(text: e.address));
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('Address copied'),
                                            behavior:
                                                SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } else if (action == 'delete') {
                                      await ref
                                          .read(addressBookProvider.notifier)
                                          .remove(e.id);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'copy',
                                      child: Text('Copy address'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(
                                            color: Colors.redAccent.shade200),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _userFacingError(Object e) {
    final s = e.toString();
    const p = 'Bad state: ';
    if (s.startsWith(p)) return s.substring(p.length);
    return s;
  }

  static Future<void> _showAddOrEditDialog(
    BuildContext context,
    WidgetRef ref,
    AddressBookEntry? existing,
  ) async {
    final labelCtrl = TextEditingController(text: existing?.label);
    final addrCtrl = TextEditingController(text: existing?.address);
    AssetId asset = AssetId.eth;
    if (existing != null) {
      for (final a in AssetId.values) {
        if (a.name == existing.assetKey) {
          asset = a;
          break;
        }
      }
    }

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSt) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A2A3E),
              title: Text(existing == null ? 'New contact' : 'Edit contact'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: labelCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Label',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AssetId>(
                      value: asset, // ignore: deprecated_member_use
                      decoration: const InputDecoration(
                        labelText: 'Network',
                        border: OutlineInputBorder(),
                      ),
                      items: AssetId.values
                          .map(
                            (a) => DropdownMenuItem(
                              value: a,
                              child: Text(a.ticker),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setSt(() => asset = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addrCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: (asset == AssetId.eth || asset == AssetId.vavel)
                            ? 'Address or .eth name'
                            : 'Address',
                        hintText: (asset == AssetId.eth || asset == AssetId.vavel)
                            ? '0x… or vitalik.eth'
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    try {
                      final n = ref.read(addressBookProvider.notifier);
                      if (existing == null) {
                        await n.add(
                          label: labelCtrl.text,
                          address: addrCtrl.text,
                          assetId: asset,
                        );
                      } else {
                        await n.editEntry(
                          id: existing.id,
                          label: labelCtrl.text,
                          address: addrCtrl.text,
                          assetId: asset,
                        );
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(_userFacingError(e)),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Text(existing == null ? 'Save' : 'Update'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      labelCtrl.dispose();
      addrCtrl.dispose();
    }
  }
}
