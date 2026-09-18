import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../../../../services/serials_service.dart';
import '../order_detail_controller.dart';

class SerialLinkPanel extends StatefulWidget {
  final OrderDetailController controller;

  const SerialLinkPanel({super.key, required this.controller});

  @override
  State<SerialLinkPanel> createState() => _SerialLinkPanelState();
}

class _SerialLinkPanelState extends State<SerialLinkPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  final _serialCtrl = TextEditingController();
  final _serialFocus = FocusNode();

  final _matchSerialCtrl = TextEditingController();
  final _matchInventoryCtrl = TextEditingController();
  final _matchSerialFocus = FocusNode();

  bool _assigning = false;
  String? _assignError;
  String? _lastInventory;

  bool _matching = false;
  String? _matchError;

  bool _uploading = false;
  String? _uploadFileName;
  Uint8List? _uploadBytes;
  String? _uploadResult;

  bool _loadingRecent = false;
  List<Map<String, String?>> _recent = [];

  String get _orderNbr =>
      widget.controller.detail?.agentOrder.orderNbr ?? '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(_onTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecent();
      _serialFocus.requestFocus();
    });
  }

  void _onTabChange() {
    if (!_tabs.indexIsChanging) return;
    if (_tabs.index == 3) _loadRecent();
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChange);
    _tabs.dispose();
    _serialCtrl.dispose();
    _serialFocus.dispose();
    _matchSerialCtrl.dispose();
    _matchInventoryCtrl.dispose();
    _matchSerialFocus.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _doAssign() async {
    final serial = _serialCtrl.text.trim();
    if (serial.isEmpty) return;
    setState(() {
      _assigning = true;
      _assignError = null;
    });
    try {
      final result =
          await SerialsService.instance.assignSerial(_orderNbr, serial);
      if (!mounted) return;
      final code = result['inventory_code']?.toString();
      setState(() {
        _lastInventory = code;
      });
      _serialCtrl.clear();
      _serialFocus.requestFocus();
      _showSnack('Serial asignado${code != null ? ': $code' : ''}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _assignError = e.toString());
    } finally {
      if (mounted) setState(() => _assigning = false);
    }
  }

  Future<void> _doMatch() async {
    final serial = _matchSerialCtrl.text.trim();
    final inventory = _matchInventoryCtrl.text.trim();
    if (serial.isEmpty || inventory.isEmpty) {
      _showSnack('Completa serial e inventario/IMEI');
      return;
    }
    setState(() {
      _matching = true;
      _matchError = null;
    });
    try {
      await SerialsService.instance.matchSerials(_orderNbr, serial, inventory);
      if (!mounted) return;
      _matchSerialCtrl.clear();
      _matchInventoryCtrl.clear();
      _matchSerialFocus.requestFocus();
      _showSnack('Emparejado correctamente');
    } catch (e) {
      if (!mounted) return;
      setState(() => _matchError = e.toString());
    } finally {
      if (mounted) setState(() => _matching = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    final bytes =
        f.bytes ?? (f.path != null ? null : null);
    if (bytes == null) {
      _showSnack('No se pudo leer el archivo');
      return;
    }
    setState(() {
      _uploadFileName = f.name;
      _uploadBytes = bytes;
      _uploadResult = null;
    });
  }

  Future<void> _doUpload() async {
    final bytes = _uploadBytes;
    final name = _uploadFileName;
    if (bytes == null || name == null) return;
    setState(() => _uploading = true);
    try {
      final res = await SerialsService.instance.uploadSerials(bytes, name);
      if (!mounted) return;
      final inserted = res['inserted'] ?? 0;
      final skipped = res['skipped'] ?? 0;
      final errors = (res['errors'] as List?)?.length ?? 0;
      setState(() =>
          _uploadResult = 'Insertados: $inserted  Saltados: $skipped  Errores: $errors');
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadResult = 'Error: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _loadRecent() async {
    if (_orderNbr.isEmpty) return;
    setState(() => _loadingRecent = true);
    try {
      final rows = await SerialsService.instance.getRecentSerials(_orderNbr);
      if (!mounted) return;
      setState(() => _recent = rows);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingRecent = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    return AnimatedOpacity(
      opacity: 1,
      duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 220),
      child: AnimatedScale(
        scale: 1,
        duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: Column(
          children: [
            _TabBarRow(tabs: _tabs, ct: ct),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _AssignTab(
                    ct: ct,
                    serialCtrl: _serialCtrl,
                    serialFocus: _serialFocus,
                    assigning: _assigning,
                    assignError: _assignError,
                    lastInventory: _lastInventory,
                    onAssign: _doAssign,
                  ),
                  _MatchTab(
                    ct: ct,
                    serialCtrl: _matchSerialCtrl,
                    inventoryCtrl: _matchInventoryCtrl,
                    serialFocus: _matchSerialFocus,
                    matching: _matching,
                    matchError: _matchError,
                    onMatch: _doMatch,
                  ),
                  _UploadTab(
                    ct: ct,
                    fileName: _uploadFileName,
                    bytes: _uploadBytes,
                    uploading: _uploading,
                    result: _uploadResult,
                    onPickFile: _pickFile,
                    onUpload: _doUpload,
                  ),
                  _RecentTab(
                    ct: ct,
                    loading: _loadingRecent,
                    rows: _recent,
                    onRefresh: _loadRecent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBarRow extends StatelessWidget {
  final TabController tabs;
  final CobaltPalette ct;

  const _TabBarRow({required this.tabs, required this.ct});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ct.surface,
      child: TabBar(
        controller: tabs,
        indicatorColor: CobaltColors.cobalt,
        indicatorWeight: 2.5,
        labelColor: CobaltColors.cobaltLight,
        unselectedLabelColor: ct.textSecondary,
        labelStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.4),
        unselectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'Asignar'),
          Tab(text: 'Emparejar'),
          Tab(text: 'Subir'),
          Tab(text: 'Recientes'),
        ],
      ),
    );
  }
}

// ── Tab 1: Asignar ───────────────────────────────────────────────────────────

class _AssignTab extends StatelessWidget {
  final CobaltPalette ct;
  final TextEditingController serialCtrl;
  final FocusNode serialFocus;
  final bool assigning;
  final String? assignError;
  final String? lastInventory;
  final VoidCallback onAssign;

  const _AssignTab({
    required this.ct,
    required this.serialCtrl,
    required this.serialFocus,
    required this.assigning,
    required this.assignError,
    required this.lastInventory,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Asignar serial',
            style: TextStyle(
                color: ct.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Escanea o escribe el serial. El sistema asignará la siguiente etiqueta de inventario disponible.',
            style: TextStyle(color: ct.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CobaltField(
                  controller: serialCtrl,
                  focusNode: serialFocus,
                  ct: ct,
                  label: 'Serial',
                  hint: 'Escanear o escribir serial',
                  prefixIcon: Icons.qr_code_scanner_rounded,
                  onSubmitted: (_) => onAssign(),
                ),
              ),
              const SizedBox(width: 12),
              _CobaltButton(
                label: assigning ? 'Asignando...' : 'Asignar',
                loading: assigning,
                onPressed: assigning ? null : onAssign,
              ),
            ],
          ),
          if (assignError != null) ...[
            const SizedBox(height: 10),
            Text(assignError!,
                style: const TextStyle(
                    color: Color(0xFFE05252), fontSize: 12)),
          ],
          if (lastInventory != null) ...[
            const SizedBox(height: 14),
            _InfoChip(ct: ct, label: 'Último inventario: $lastInventory'),
          ],
        ],
      ),
    );
  }
}

// ── Tab 2: Emparejar ─────────────────────────────────────────────────────────

class _MatchTab extends StatelessWidget {
  final CobaltPalette ct;
  final TextEditingController serialCtrl;
  final TextEditingController inventoryCtrl;
  final FocusNode serialFocus;
  final bool matching;
  final String? matchError;
  final VoidCallback onMatch;

  const _MatchTab({
    required this.ct,
    required this.serialCtrl,
    required this.inventoryCtrl,
    required this.serialFocus,
    required this.matching,
    required this.matchError,
    required this.onMatch,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emparejar serial con inventario',
            style: TextStyle(
                color: ct.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Vincula un serial de origen con su código de inventario o IMEI destino.',
            style: TextStyle(color: ct.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _CobaltField(
            controller: serialCtrl,
            focusNode: serialFocus,
            ct: ct,
            label: 'Serial / SN origen',
            hint: 'Escanear serial',
            prefixIcon: Icons.qr_code_scanner_rounded,
          ),
          const SizedBox(height: 14),
          _CobaltField(
            controller: inventoryCtrl,
            ct: ct,
            label: 'Inventario / IMEI destino',
            hint: 'Escanear inventario o IMEI',
            prefixIcon: Icons.inventory_2_rounded,
            onSubmitted: (_) => onMatch(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: _CobaltButton(
              label: matching ? 'Emparejando...' : 'Emparejar',
              loading: matching,
              onPressed: matching ? null : onMatch,
            ),
          ),
          if (matchError != null) ...[
            const SizedBox(height: 10),
            Text(matchError!,
                style: const TextStyle(
                    color: Color(0xFFE05252), fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

// ── Tab 3: Subir ─────────────────────────────────────────────────────────────

class _UploadTab extends StatelessWidget {
  final CobaltPalette ct;
  final String? fileName;
  final Uint8List? bytes;
  final bool uploading;
  final String? result;
  final VoidCallback onPickFile;
  final VoidCallback onUpload;

  const _UploadTab({
    required this.ct,
    required this.fileName,
    required this.bytes,
    required this.uploading,
    required this.result,
    required this.onPickFile,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Carga masiva de seriales',
            style: TextStyle(
                color: ct.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Selecciona un archivo CSV o TXT con un serial por línea.',
            style: TextStyle(color: ct.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _FilePicker(ct: ct, fileName: fileName, onPick: onPickFile),
          if (bytes != null && fileName != null) ...[
            const SizedBox(height: 14),
            _FilePreview(ct: ct, fileName: fileName!, bytes: bytes!),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: _CobaltButton(
                label: uploading ? 'Subiendo...' : 'Subir y asignar',
                loading: uploading,
                onPressed: uploading ? null : onUpload,
              ),
            ),
          ],
          if (result != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ct.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ct.border),
              ),
              child: Text(result!,
                  style: TextStyle(
                      color: ct.textPrimary,
                      fontSize: 13,
                      fontFamily: 'monospace')),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Tab 4: Recientes ─────────────────────────────────────────────────────────

class _RecentTab extends StatelessWidget {
  final CobaltPalette ct;
  final bool loading;
  final List<Map<String, String?>> rows;
  final VoidCallback onRefresh;

  const _RecentTab({
    required this.ct,
    required this.loading,
    required this.rows,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                'Seriales recientes',
                style: TextStyle(
                    color: ct.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              AnimatedScale(
                scale: 1,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                child: IconButton(
                  icon: Icon(Icons.refresh_rounded, color: ct.textSecondary),
                  onPressed: loading ? null : onRefresh,
                  tooltip: 'Actualizar',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? Center(
                  child: CircularProgressIndicator(
                      color: CobaltColors.cobaltLight))
              : rows.isEmpty
                  ? Center(
                      child: Text(
                      'Sin seriales procesados para esta orden',
                      style: TextStyle(
                          color: ct.textHint, fontSize: 13),
                    ))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: rows.length,
                      separatorBuilder: (context2, idx) => Divider(
                            height: 1,
                            color: ct.border,
                          ),
                      itemBuilder: (_, i) {
                        final row = rows[i];
                        return _RecentRow(
                          ct: ct,
                          index: i + 1,
                          serial: row['serial'],
                          inventoryCode: row['inventory_code'],
                          assignedAt: row['assigned_at'],
                        );
                      }),
        ),
      ],
    );
  }
}

// ── Shared small widgets ─────────────────────────────────────────────────────

class _CobaltField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final CobaltPalette ct;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final ValueChanged<String>? onSubmitted;

  const _CobaltField({
    required this.controller,
    this.focusNode,
    required this.ct,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: TextStyle(color: ct.textPrimary, fontSize: 14),
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: ct.textSecondary, fontSize: 13),
        hintStyle: TextStyle(color: ct.textHint, fontSize: 13),
        prefixIcon: Icon(prefixIcon, color: ct.textSecondary, size: 18),
        filled: true,
        fillColor: ct.surfaceElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ct.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ct.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: CobaltColors.cobaltLight, width: 1.5),
        ),
      ),
    );
  }
}

class _CobaltButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const _CobaltButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: onPressed == null ? 1.0 : 0.97,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: CobaltColors.cobalt,
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final CobaltPalette ct;
  final String label;

  const _InfoChip({required this.ct, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ct.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ct.border),
      ),
      child: Text(label,
          style: TextStyle(color: ct.textSecondary, fontSize: 12)),
    );
  }
}

class _FilePicker extends StatelessWidget {
  final CobaltPalette ct;
  final String? fileName;
  final VoidCallback onPick;

  const _FilePicker(
      {required this.ct, required this.fileName, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: ct.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: fileName != null
                ? CobaltColors.cobaltLight
                : ct.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              fileName != null
                  ? Icons.description_rounded
                  : Icons.upload_file_rounded,
              color: fileName != null
                  ? CobaltColors.cobaltLight
                  : ct.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fileName ?? 'Seleccionar archivo CSV o TXT',
                style: TextStyle(
                  color: fileName != null ? ct.textPrimary : ct.textHint,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              'Examinar',
              style: TextStyle(
                  color: CobaltColors.cobaltLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilePreview extends StatelessWidget {
  final CobaltPalette ct;
  final String fileName;
  final Uint8List bytes;

  const _FilePreview(
      {required this.ct, required this.fileName, required this.bytes});

  @override
  Widget build(BuildContext context) {
    final lines = String.fromCharCodes(bytes).split('\n');
    final preview = lines.take(8).join('\n');
    final remaining = lines.length - 8;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ct.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ct.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                fileName,
                style: TextStyle(
                    color: ct.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${lines.length} líneas',
                style: TextStyle(color: ct.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            preview,
            style: TextStyle(
                color: ct.textSecondary,
                fontSize: 11,
                fontFamily: 'monospace'),
          ),
          if (remaining > 0)
            Text(
              '...y $remaining más',
              style: TextStyle(color: ct.textHint, fontSize: 11),
            ),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  final CobaltPalette ct;
  final int index;
  final String? serial;
  final String? inventoryCode;
  final String? assignedAt;

  const _RecentRow({
    required this.ct,
    required this.index,
    required this.serial,
    required this.inventoryCode,
    required this.assignedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$index',
              style: TextStyle(
                  color: ct.textHint,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inventoryCode ?? '—',
                  style: TextStyle(
                      color: ct.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                if (serial != null)
                  Text(
                    serial!,
                    style: TextStyle(color: ct.textSecondary, fontSize: 11),
                  ),
              ],
            ),
          ),
          if (assignedAt != null)
            Text(
              _formatDate(assignedAt!),
              style: TextStyle(color: ct.textHint, fontSize: 11),
            ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }
}
