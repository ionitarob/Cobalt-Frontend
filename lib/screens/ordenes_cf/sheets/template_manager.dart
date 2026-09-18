import 'package:flutter/material.dart';

import '../../../core/cobalt_theme.dart';
import '../../../core/colors.dart';
import '../../../models/orderops/order_task.dart';
import '../../../services/orderops/templates_service.dart';

class TemplateManager extends StatefulWidget {
  final VoidCallback onClose;

  const TemplateManager({super.key, required this.onClose});

  @override
  State<TemplateManager> createState() => _TemplateManagerState();
}

class _TemplateManagerState extends State<TemplateManager> {
  List<ChecklistTemplate> _templates = [];
  ChecklistTemplate? _selected;
  bool _loading = true;
  bool _saving = false;

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _familyCtrl = TextEditingController();
  final _newItemCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _familyCtrl.dispose();
    _newItemCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await TemplatesService.instance.getTemplates();
      if (mounted) setState(() { _templates = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectTemplate(ChecklistTemplate t) {
    setState(() {
      _selected = t;
      _nameCtrl.text = t.name;
      _descCtrl.text = t.description ?? '';
      _familyCtrl.text = t.family ?? '';
    });
  }

  void _newTemplate() {
    setState(() {
      _selected = null;
      _nameCtrl.clear();
      _descCtrl.clear();
      _familyCtrl.clear();
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      if (_selected == null) {
        final created = await TemplatesService.instance.createTemplate(
          name: name,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          family: _familyCtrl.text.trim().isEmpty ? null : _familyCtrl.text.trim(),
        );
        await _load();
        if (mounted) {
          final updated = _templates.firstWhere((t) => t.id == created.id, orElse: () => created);
          setState(() { _selected = updated; _saving = false; });
        }
      } else {
        await TemplatesService.instance.updateTemplate(
          _selected!.id,
          name: name,
          description: _descCtrl.text.trim(),
          family: _familyCtrl.text.trim(),
        );
        await _load();
        if (mounted) {
          final updated = _templates.firstWhere((t) => t.id == _selected!.id,
              orElse: () => _selected!);
          setState(() { _selected = updated; _saving = false; });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(ChecklistTemplate t) async {
    try {
      await TemplatesService.instance.deleteTemplate(t.id);
      await _load();
      if (mounted) setState(() { if (_selected?.id == t.id) _selected = null; });
    } catch (_) {}
  }

  Future<void> _addItem() async {
    if (_selected == null) return;
    final titulo = _newItemCtrl.text.trim();
    if (titulo.isEmpty) return;
    try {
      await TemplatesService.instance.addItem(_selected!.id, titulo);
      _newItemCtrl.clear();
      await _load();
      if (mounted) {
        setState(() {
          _selected = _templates.firstWhere((t) => t.id == _selected!.id, orElse: () => _selected!);
        });
      }
    } catch (_) {}
  }

  Future<void> _deleteItem(int itemId) async {
    if (_selected == null) return;
    try {
      await TemplatesService.instance.deleteItem(_selected!.id, itemId);
      await _load();
      if (mounted) {
        setState(() {
          _selected = _templates.firstWhere((t) => t.id == _selected!.id, orElse: () => _selected!);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Container(
      width: 700,
      decoration: BoxDecoration(
        color: ct.surface,
        border: Border(left: BorderSide(color: ct.border)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(-4, 0))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(ct),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: CobaltColors.cobaltLight))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _templateList(ct),
                      Container(width: 1, color: ct.border),
                      Expanded(child: _detailPane(ct)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header(CobaltPalette ct) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ct.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.checklist_rounded, size: 16, color: CobaltColors.cobaltLight),
          const SizedBox(width: 8),
          Text('Gestión de plantillas',
              style: TextStyle(color: ct.textPrimary,
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          _HeaderBtn(icon: Icons.add_rounded, label: 'Nueva', onTap: _newTemplate),
          const SizedBox(width: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.onClose,
              child: Icon(Icons.close_rounded, size: 16, color: ct.textHint),
            ),
          ),
        ],
      ),
    );
  }

  Widget _templateList(CobaltPalette ct) {
    return SizedBox(
      width: 240,
      child: ListView.builder(
        itemCount: _templates.length,
        itemBuilder: (_, i) {
          final t = _templates[i];
          final sel = _selected?.id == t.id;
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _selectTemplate(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? CobaltColors.cobalt.withValues(alpha: 0.10) : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                        color: sel ? CobaltColors.cobaltLight : Colors.transparent,
                        width: 2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name,
                              style: TextStyle(
                                  color: sel ? CobaltColors.cobaltLight : ct.textPrimary,
                                  fontSize: 13,
                                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400),
                              overflow: TextOverflow.ellipsis),
                          if (t.family != null)
                            Text(t.family!,
                                style: TextStyle(
                                    color: ct.textHint, fontSize: 11)),
                          Text('${t.items.length} ítems',
                              style: TextStyle(
                                  color: ct.textHint, fontSize: 10)),
                        ],
                      ),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _delete(t),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.delete_outline_rounded,
                              size: 14, color: ct.textHint),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _detailPane(CobaltPalette ct) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_selected == null && _templates.isNotEmpty)
          Center(
            child: Text('Selecciona una plantilla o crea una nueva.',
                style: TextStyle(color: ct.textHint, fontSize: 13)),
          )
        else ...[
          Text(_selected == null ? 'Nueva plantilla' : 'Editar plantilla',
              style: TextStyle(color: ct.textPrimary,
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          _textField(ct, 'Nombre *', _nameCtrl, Icons.label_outline_rounded),
          const SizedBox(height: 10),
          _textField(ct, 'Familia', _familyCtrl, Icons.inventory_2_outlined),
          const SizedBox(height: 10),
          _textField(ct, 'Descripción', _descCtrl, Icons.notes_rounded),
          const SizedBox(height: 14),
          _saveBtn(ct),
          if (_selected != null) ...[
            const SizedBox(height: 20),
            Divider(color: ct.border),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Ítems de la plantilla',
                    style: TextStyle(color: ct.textPrimary,
                        fontSize: 12, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${_selected!.items.length} total',
                    style: TextStyle(color: ct.textHint, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),
            ..._selected!.items.map((item) => _itemRow(ct, item)),
            const SizedBox(height: 8),
            _addItemRow(ct),
          ],
        ],
      ],
    );
  }

  Widget _itemRow(CobaltPalette ct, ChecklistTemplateItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ct.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ct.border),
      ),
      child: Row(
        children: [
          Icon(Icons.drag_indicator_rounded,
              size: 14, color: ct.textHint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(item.titulo,
                style: TextStyle(
                    color: ct.textPrimary, fontSize: 12)),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _deleteItem(item.id),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded,
                    size: 13, color: ct.textHint),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addItemRow(CobaltPalette ct) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _newItemCtrl,
            onSubmitted: (_) => _addItem(),
            style: TextStyle(color: ct.textPrimary, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Nuevo ítem…',
              hintStyle: TextStyle(color: ct.textHint, fontSize: 12),
              filled: true,
              fillColor: ct.background,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: ct.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: ct.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: CobaltColors.cobaltLight, width: 1.5)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _addItem,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: CobaltColors.cobalt.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: CobaltColors.cobalt.withValues(alpha: 0.35)),
              ),
              child: const Icon(Icons.add_rounded, size: 16, color: CobaltColors.cobaltLight),
            ),
          ),
        ),
      ],
    );
  }

  Widget _textField(CobaltPalette ct, String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      style: TextStyle(color: ct.textPrimary, fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: ct.textHint, fontSize: 11),
        prefixIcon: Icon(icon, size: 14, color: ct.textHint),
        filled: true,
        fillColor: ct.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: ct.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: ct.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: CobaltColors.cobaltLight, width: 1.5)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _saveBtn(CobaltPalette ct) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _saving ? null : _save,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [CobaltColors.cobalt, CobaltColors.cobaltLight]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: _saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_selected == null ? 'Crear plantilla' : 'Guardar',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

class _HeaderBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.label, required this.onTap});

  @override
  State<_HeaderBtn> createState() => _HeaderBtnState();
}

class _HeaderBtnState extends State<_HeaderBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered ? CobaltColors.cobalt.withValues(alpha: 0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ct.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 13, color: CobaltColors.cobaltLight),
              const SizedBox(width: 5),
              Text(widget.label,
                  style: const TextStyle(
                      color: CobaltColors.cobaltLight, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
