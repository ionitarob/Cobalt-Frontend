import 'package:flutter/material.dart';
import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../../../../services/sentinel_service.dart';
import '../order_detail_controller.dart';

class MasterizacionPanel extends StatefulWidget {
  final OrderDetailController controller;
  const MasterizacionPanel({super.key, required this.controller});

  @override
  State<MasterizacionPanel> createState() => _MasterizacionPanelState();
}

class _MasterizacionPanelState extends State<MasterizacionPanel> {
  List<PhysicalTable> _tables = [];
  bool _loading = false;
  String? _error;
  int? _lastLoadedIdnbr;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);
    _tryLoad();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    final idnbr = widget.controller.detail?.agentOrder.idnbr;
    if (idnbr != null && idnbr != _lastLoadedIdnbr) _tryLoad();
  }

  Future<void> _tryLoad() async {
    final idnbr = widget.controller.detail?.agentOrder.idnbr;
    if (idnbr == null) return;
    _lastLoadedIdnbr = idnbr;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tables = await SentinelService.instance.getPhysicalTables(idnbr);
      if (mounted) setState(() => _tables = tables);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalSlots =>
      _tables.fold(0, (s, t) => s + t.totalSlots);
  int get _completedSlots =>
      _tables.fold(0, (s, t) => s + t.completedSlots);
  int get _inProgressSlots =>
      _tables.fold(0, (s, t) => s + t.inProgressSlots);

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          totalSlots: _totalSlots,
          completedSlots: _completedSlots,
          inProgressSlots: _inProgressSlots,
          onRefresh: _tryLoad,
        ),
        const SizedBox(height: 1),
        Expanded(child: _body(ct)),
      ],
    );
  }

  Widget _body(CobaltPalette ct) {
    if (_loading) {
      return Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor:
                AlwaysStoppedAnimation<Color>(CobaltColors.cobaltLight),
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.signal_wifi_connected_no_internet_4_rounded,
                color: ct.textHint, size: 36),
            const SizedBox(height: 12),
            Text(
              'No se pudo cargar las mesas',
              style: TextStyle(
                  color: ct.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              _error!,
              style: TextStyle(color: ct.textHint, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _tryLoad,
              icon:
                  Icon(Icons.refresh_rounded, color: CobaltColors.cobaltLight),
              label: Text(
                'Reintentar',
                style: TextStyle(color: CobaltColors.cobaltLight),
              ),
            ),
          ],
        ),
      );
    }

    if (_tables.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.table_restaurant_rounded, color: ct.textHint, size: 36),
            const SizedBox(height: 12),
            Text(
              'Sin mesas asignadas a esta orden',
              style: TextStyle(color: ct.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _tables.length,
      itemBuilder: (context, index) => _TableCard(
        table: _tables[index],
        index: index,
        onSlotTap: (slot) => _showSlotSheet(context, slot, _tables[index]),
      ),
    );
  }

  void _showSlotSheet(
      BuildContext context, TableSlot slot, PhysicalTable table) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SlotDetailSheet(
        slot: slot,
        tableName: table.name,
        onStatusChange: (status) async {
          final nav = Navigator.of(context);
          final messenger = ScaffoldMessenger.of(context);
          nav.pop();
          try {
            await SentinelService.instance
                .updateDeviceStatus(slot.id, status);
            await _tryLoad();
          } catch (e) {
            messenger.showSnackBar(SnackBar(
              content: Text('Error actualizando estado: $e'),
              backgroundColor:
                  const Color(0xFFFF5252).withValues(alpha: 0.9),
            ));
          }
        },
        onRegisterDevice: (hostname, mac) async {
          final nav = Navigator.of(context);
          final messenger = ScaffoldMessenger.of(context);
          nav.pop();
          final idnbr = widget.controller.detail?.agentOrder.idnbr;
          try {
            await SentinelService.instance.registerDevice({
              'port_id': slot.id,
              'hostname': hostname,
              'mac': mac,
              'order_id': idnbr,
            });
            await _tryLoad();
          } catch (e) {
            messenger.showSnackBar(SnackBar(
              content: Text('Error registrando dispositivo: $e'),
              backgroundColor:
                  const Color(0xFFFF5252).withValues(alpha: 0.9),
            ));
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final int totalSlots;
  final int completedSlots;
  final int inProgressSlots;
  final VoidCallback onRefresh;

  const _Header({
    required this.totalSlots,
    required this.completedSlots,
    required this.inProgressSlots,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
      decoration: BoxDecoration(
        color: ct.surface,
        border: Border(
          bottom: BorderSide(color: ct.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.table_restaurant_rounded,
              color: CobaltColors.cobaltLight, size: 18),
          const SizedBox(width: 10),
          Text(
            'Mesas de Maquetación',
            style: TextStyle(
              color: ct.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(width: 12),
          if (totalSlots > 0) ...[
            _StatPill(
              label: 'Total',
              value: totalSlots,
              color: ct.textSecondary,
            ),
            const SizedBox(width: 6),
            _StatPill(
              label: 'Completados',
              value: completedSlots,
              color: const Color(0xFF69F0AE),
            ),
            const SizedBox(width: 6),
            _StatPill(
              label: 'En progreso',
              value: inProgressSlots,
              color: CobaltColors.cobaltLight,
            ),
          ],
          const Spacer(),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.refresh_rounded,
                  color: ct.textSecondary, size: 18),
              onPressed: onRefresh,
              tooltip: 'Actualizar',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Table Card
// ---------------------------------------------------------------------------

class _TableCard extends StatefulWidget {
  final PhysicalTable table;
  final int index;
  final void Function(TableSlot) onSlotTap;

  const _TableCard({
    required this.table,
    required this.index,
    required this.onSlotTap,
  });

  @override
  State<_TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<_TableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.95, end: 1.0)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    final delay = widget.index * 50;
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted &&
          !MediaQuery.of(context).disableAnimations) {
        _animCtrl.forward();
      } else if (mounted) {
        _animCtrl.value = 1.0;
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final table = widget.table;
    final progress = table.totalSlots > 0
        ? table.completedSlots / table.totalSlots
        : 0.0;

    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: ct.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ct.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  children: [
                    Icon(Icons.hub_rounded,
                        color: CobaltColors.cobaltLight, size: 15),
                    const SizedBox(width: 8),
                    Text(
                      table.name.toUpperCase(),
                      style: TextStyle(
                        color: ct.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${table.completedSlots}/${table.totalSlots}',
                      style: TextStyle(
                        color: CobaltColors.cobaltLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (table.totalSlots > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      backgroundColor:
                          CobaltColors.cobaltLight.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        CobaltColors.cobaltLight,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: table.slots
                      .map((slot) => _SlotChip(
                            slot: slot,
                            onTap: () => widget.onSlotTap(slot),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slot Chip
// ---------------------------------------------------------------------------

Color _stageColor(String stage) {
  switch (stage) {
    case 'completo':
      return const Color(0xFF69F0AE);
    case 'maquetando':
      return CobaltColors.cobaltLight;
    case 'error':
      return const Color(0xFFFF5252);
    default:
      return CobaltColors.textHint;
  }
}

class _SlotChip extends StatefulWidget {
  final TableSlot slot;
  final VoidCallback onTap;

  const _SlotChip({required this.slot, required this.onTap});

  @override
  State<_SlotChip> createState() => _SlotChipState();
}

class _SlotChipState extends State<_SlotChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final slot = widget.slot;
    final color = _stageColor(slot.stage);
    final hasDevice = slot.hostname != null || slot.connectedMac != null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Container(
          width: 62,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: slot.stage == 'libre' ? 0.04 : 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: color.withValues(alpha: slot.stage == 'libre' ? 0.2 : 0.5),
              width: slot.stage == 'libre' ? 1.0 : 1.5,
            ),
            boxShadow: slot.stage != 'libre'
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 6,
                      spreadRadius: 0,
                    )
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  '${slot.portNumber}',
                  style: TextStyle(
                    color: slot.stage == 'libre'
                        ? ct.textHint
                        : color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (hasDevice)
                Positioned(
                  bottom: 2,
                  left: 2,
                  right: 2,
                  child: Text(
                    (slot.hostname ?? slot.connectedMac ?? '').split('.').first,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.8),
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              // Stage indicator dot top-right
              Positioned(
                top: 3,
                right: 3,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: slot.stage != 'libre'
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.6),
                              blurRadius: 3,
                            )
                          ]
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slot Detail Sheet
// ---------------------------------------------------------------------------

class _SlotDetailSheet extends StatefulWidget {
  final TableSlot slot;
  final String tableName;
  final Future<void> Function(String status) onStatusChange;
  final Future<void> Function(String hostname, String mac) onRegisterDevice;

  const _SlotDetailSheet({
    required this.slot,
    required this.tableName,
    required this.onStatusChange,
    required this.onRegisterDevice,
  });

  @override
  State<_SlotDetailSheet> createState() => _SlotDetailSheetState();
}

class _SlotDetailSheetState extends State<_SlotDetailSheet> {
  final _hostnameCtrl = TextEditingController();
  final _macCtrl = TextEditingController();
  bool _showRegisterForm = false;

  @override
  void dispose() {
    _hostnameCtrl.dispose();
    _macCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final slot = widget.slot;
    final stageColor = _stageColor(slot.stage);

    return Container(
      decoration: BoxDecoration(
        color: ct.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: ct.border)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: ct.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title row
          Row(
            children: [
              Text(
                widget.tableName.toUpperCase(),
                style: TextStyle(
                  color: CobaltColors.cobaltLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '— Puerto ${slot.portNumber}',
                style: TextStyle(
                  color: ct.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: stageColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: stageColor.withValues(alpha: 0.45)),
                ),
                child: Text(
                  _stageLabel(slot.stage),
                  style: TextStyle(
                    color: stageColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Device info
          if (slot.hostname != null || slot.connectedMac != null) ...[
            _InfoRow(
              icon: Icons.computer_rounded,
              label: 'Dispositivo',
              value: slot.hostname ?? '—',
              ct: ct,
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.settings_ethernet_rounded,
              label: 'MAC',
              value: slot.connectedMac ?? '—',
              ct: ct,
            ),
            const SizedBox(height: 16),
          ],

          // Action buttons
          if (slot.stage != 'libre') ...[
            Text(
              'Cambiar estado',
              style: TextStyle(
                color: ct.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (slot.stage != 'maquetando')
                  _ActionButton(
                    label: 'Iniciar maquetación',
                    color: CobaltColors.cobaltLight,
                    onTap: () => widget.onStatusChange('maquetando'),
                  ),
                if (slot.stage != 'completo')
                  _ActionButton(
                    label: 'Marcar completado',
                    color: const Color(0xFF69F0AE),
                    onTap: () => widget.onStatusChange('completo'),
                  ),
                if (slot.stage != 'error')
                  _ActionButton(
                    label: 'Marcar error',
                    color: const Color(0xFFFF5252),
                    onTap: () => widget.onStatusChange('error'),
                  ),
                _ActionButton(
                  label: 'Liberar slot',
                  color: ct.textHint,
                  onTap: () => widget.onStatusChange('libre'),
                ),
              ],
            ),
          ],

          // Register device section (visible when slot is libre)
          if (slot.stage == 'libre') ...[
            if (!_showRegisterForm)
              TextButton.icon(
                onPressed: () =>
                    setState(() => _showRegisterForm = true),
                icon: Icon(Icons.add_rounded,
                    color: CobaltColors.cobaltLight, size: 18),
                label: Text(
                  'Registrar dispositivo',
                  style: TextStyle(color: CobaltColors.cobaltLight),
                ),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.zero,
                ),
              )
            else ...[
              Text(
                'Registrar dispositivo',
                style: TextStyle(
                  color: ct.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),
              _CobaltTextField(
                controller: _hostnameCtrl,
                hint: 'Nombre del equipo (opcional)',
                ct: ct,
              ),
              const SizedBox(height: 8),
              _CobaltTextField(
                controller: _macCtrl,
                hint: 'Dirección MAC (opcional)',
                ct: ct,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () =>
                        setState(() => _showRegisterForm = false),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: ct.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CobaltColors.cobalt,
                      foregroundColor: CobaltColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onPressed: () => widget.onRegisterDevice(
                      _hostnameCtrl.text.trim(),
                      _macCtrl.text.trim(),
                    ),
                    child: const Text('Registrar',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _stageLabel(String stage) {
    switch (stage) {
      case 'completo':
        return 'COMPLETADO';
      case 'maquetando':
        return 'MAQUETANDO';
      case 'error':
        return 'ERROR';
      default:
        return 'LIBRE';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final CobaltPalette ct;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.ct,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: ct.textHint, size: 14),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
              color: ct.textSecondary, fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: ct.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: widget.color.withValues(alpha: 0.45)),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CobaltTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final CobaltPalette ct;

  const _CobaltTextField({
    required this.controller,
    required this.hint,
    required this.ct,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(color: ct.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: ct.textHint, fontSize: 13),
        filled: true,
        fillColor: ct.surfaceElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ct.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: CobaltColors.cobaltLight, width: 1.5),
        ),
      ),
    );
  }
}
