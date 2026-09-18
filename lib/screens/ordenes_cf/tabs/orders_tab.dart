import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/cobalt_theme.dart';
import '../../../models/orderops/agent_order.dart';
import '../../../services/orderops/orders_service.dart';
import '../../../services/orderops/sync_service.dart';
import '../widgets/bulk_action_bar.dart';
import '../widgets/filter_bar.dart';
import '../widgets/order_table.dart';
import '../widgets/toolbar_row.dart';

class OrdersTab extends StatefulWidget {
  final bool isAdmin;

  const OrdersTab({super.key, required this.isAdmin});

  @override
  State<OrdersTab> createState() => OrdersTabState();
}

class OrdersTabState extends State<OrdersTab> {
  final _searchCtrl = TextEditingController();

  List<AgentOrder> _all = [];
  List<AgentOrder> _filtered = [];
  int _totalCount = 0;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  Timer? _debounce;

  String? _estadoFilter;
  bool _filterByMe = false;
  String? _currentUserId;
  bool _loading = true;
  String? _error;
  bool _syncing = false;
  bool _exporting = false;
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    load();
  }

  Future<void> _loadCurrentUser() async {
    const storage = FlutterSecureStorage();
    _currentUserId = await storage.read(key: 'user_id');
  }

  Future<void> load() async {
    setState(() { _loading = true; _error = null; _all = []; _hasMore = false; });
    await _fetchPage(0);
  }

  Future<void> _fetchPage(int offset) async {
    try {
      final page = await OrdersService.instance.getAgentOrdersPage(
        includeSource: 1,
        search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
        estado: _estadoFilter,
        offset: offset,
        limit: 200,
      );
      if (!mounted) return;
      setState(() {
        _all = offset == 0 ? page.results : [..._all, ...page.results];
        _totalCount = page.count;
        _hasMore = _all.length < _totalCount;
        _loading = false;
        _isLoadingMore = false;
      });
      _applyFilters();
    } catch (e) {
      if (mounted) setState(() { _loading = false; _isLoadingMore = false; _error = e.toString(); });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    await _fetchPage(_all.length);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), load);
  }

  void _applyFilters() {
    setState(() {
      _filtered = _filterByMe
          ? _all.where((o) => o.assignedTo == _currentUserId).toList()
          : List.from(_all);
    });
  }

  Map<String, List<AgentOrder>> get _grouped {
    final map = <String, List<AgentOrder>>{};
    for (final o in _filtered) {
      final key = o.orderDate != null
          ? _monthKey(o.orderDate!)
          : 'Sin fecha';
      (map[key] ??= []).add(o);
    }
    return map;
  }

  String _monthKey(DateTime dt) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${months[dt.month - 1].substring(0, 1).toUpperCase()}${months[dt.month - 1].substring(1)} ${dt.year}';
  }

  bool get _allSelected {
    if (_filtered.isEmpty) return false;
    return _filtered.every((o) => _selectedIds.contains(o.idnbr));
  }

  Future<void> _startSync() async {
    setState(() => _syncing = true);
    try {
      await for (final _ in SyncService.instance.ingestOrders()) {
        // consume stream silently
      }
      await load();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final bytes = await OrdersService.instance.exportOrdersExcel();
      _saveFile(bytes, 'ordenes_export.xlsx');
    } catch (_) {
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _saveFile(Uint8List bytes, String filename) {
    // On macOS desktop, use file_saver or platform channel.
    // Placeholder: log size for now.
    debugPrint('Export: ${bytes.length} bytes → $filename');
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) _selectedIds.clear();
    });
  }

  void _onOrderTap(AgentOrder o) {
    if (_selectionMode) {
      setState(() {
        if (_selectedIds.contains(o.idnbr)) {
          _selectedIds.remove(o.idnbr);
        } else {
          _selectedIds.add(o.idnbr);
        }
      });
    }
  }

  void _onOrderLongPress(AgentOrder o) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(o.idnbr);
    });
  }

  Future<void> _bulkSetEstado(String estado) async {
    if (_selectedIds.isEmpty) return;
    try {
      await OrdersService.instance.bulkUpdateOrders(
        _selectedIds.toList(),
        estado: estado,
        forceEstado: false,
      );
      await load();
    } catch (_) {}
  }

  void _showBulkFamilyPicker() {
    _showStringPickerDialog(
      title: 'Asignar familia',
      getFuture: OrdersService.instance.getCatalogFamilies,
      onPick: (val) async {
        if (_selectedIds.isEmpty) return;
        try {
          await OrdersService.instance.bulkUpdateOrders(
            _selectedIds.toList(), family: val);
          await load();
        } catch (_) {}
      },
    );
  }

  void _showBulkEstadoPicker() {
    final options = ['1', '2', '3', '4', '5', '6'];
    final labels = ['Validada', 'Pendiente', 'En Ejecución', 'Parada', 'Finalizada', 'Facturada'];
    showDialog(
      context: context,
      builder: (_) => Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF161A20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cambiar estado',
                    style: TextStyle(color: Color(0xFFE0E6F0),
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...List.generate(options.length, (i) => ListTile(
                  title: Text(labels[i],
                      style: const TextStyle(color: Color(0xFFE0E6F0), fontSize: 13)),
                  dense: true,
                  onTap: () {
                    Navigator.of(context).pop();
                    _bulkSetEstado(options[i]);
                  },
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBulkAssignPicker() async {
    final employees = await OrdersService.instance.getEmployees(limit: 50);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            width: 320,
            constraints: const BoxConstraints(maxHeight: 400),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF161A20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Asignar a',
                    style: TextStyle(color: Color(0xFFE0E6F0),
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    itemCount: employees.length,
                    shrinkWrap: true,
                    itemBuilder: (_, i) {
                      final e = employees[i];
                      return ListTile(
                        title: Text(e['display_name']?.toString() ?? '',
                            style: const TextStyle(
                                color: Color(0xFFE0E6F0), fontSize: 13)),
                        dense: true,
                        onTap: () async {
                          Navigator.of(context).pop();
                          try {
                            await OrdersService.instance.bulkUpdateOrders(
                              _selectedIds.toList(),
                              assignedTo: e['id']?.toString(),
                              assignedToName: e['display_name']?.toString(),
                            );
                            await load();
                          } catch (_) {}
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStringPickerDialog({
    required String title,
    required Future<List<String>> Function() getFuture,
    required void Function(String) onPick,
  }) async {
    final items = await getFuture();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            width: 300,
            constraints: const BoxConstraints(maxHeight: 400),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF161A20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Color(0xFFE0E6F0),
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    itemCount: items.length,
                    shrinkWrap: true,
                    itemBuilder: (_, i) => ListTile(
                      title: Text(items[i],
                          style: const TextStyle(color: Color(0xFFE0E6F0), fontSize: 13)),
                      dense: true,
                      onTap: () { Navigator.of(context).pop(); onPick(items[i]); },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A6FDB)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF5252), size: 40),
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: Color(0xFF8899AA), fontSize: 13)),
            const SizedBox(height: 12),
            TextButton(onPressed: load, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Chips + search + toolbar — all on same 32px baseline
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: FilterBar(
                      searchController: _searchCtrl,
                      selectedEstado: _estadoFilter,
                      filterByMe: _filterByMe,
                      onEstadoChanged: (v) { setState(() => _estadoFilter = v); load(); },
                      onFilterByMeChanged: (v) { setState(() => _filterByMe = v); _applyFilters(); },
                      onSearchChanged: _onSearchChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 32,
                    child: ToolbarRow(
                      canSync: widget.isAdmin,
                      syncing: _syncing,
                      exporting: _exporting,
                      selectionMode: _selectionMode,
                      selectedCount: _selectedIds.length,
                      onSync: _startSync,
                      onExport: _export,
                      onImport: () {},
                      onToggleSelection: _toggleSelectionMode,
                      onRefresh: load,
                    ),
                  ),
                ],
              ),
              // Count sits flush below the row
              if (_totalCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _filterByMe
                        ? '${_filtered.length} de $_totalCount orden${_totalCount == 1 ? '' : 'es'}'
                        : '$_totalCount orden${_totalCount == 1 ? '' : 'es'}',
                    style: TextStyle(
                      color: context.ct.textHint,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (!_isLoadingMore && _hasMore &&
                  n.metrics.pixels >= n.metrics.maxScrollExtent - 600) {
                _loadMore();
              }
              return false;
            },
            child: OrderTable(
              grouped: _grouped,
              selectedIds: _selectedIds,
              selectionMode: _selectionMode,
              allSelected: _allSelected,
              onOrderTap: _onOrderTap,
              onOrderLongPress: _onOrderLongPress,
              onFamilyPick: (o) {},
              onSelectAll: () => setState(() =>
                  _selectedIds.addAll(_filtered.map((o) => o.idnbr))),
              onDeselectAll: () => setState(() => _selectedIds.clear()),
            ),
          ),
        ),
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF1A6FDB)),
              ),
            ),
          ),
        BulkActionBar(
          visible: _selectionMode && _selectedIds.isNotEmpty,
          count: _selectedIds.length,
          onSetFamily: _showBulkFamilyPicker,
          onSetEstado: _showBulkEstadoPicker,
          onAddNote: () {},
          onAssign: _showBulkAssignPicker,
          onCancel: () => setState(() {
            _selectionMode = false;
            _selectedIds.clear();
          }),
        ),
      ],
    );
  }
}
