import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../order_detail_controller.dart';

const Color _kWarning = Color(0xFFFFB020);
const Color _kError   = Color(0xFFFF5252);

class _LogEntry {
  final DateTime date;
  final String author;
  final String type;
  final String message;
  final String level;

  const _LogEntry({
    required this.date,
    required this.author,
    required this.type,
    required this.message,
    required this.level,
  });
}

class LogSection extends StatefulWidget {
  const LogSection({super.key, required this.controller});

  final OrderDetailController controller;

  @override
  State<LogSection> createState() => _LogSectionState();
}

class _LogSectionState extends State<LogSection> {
  bool _expanded = false;

  OrderDetailController get controller => widget.controller;

  List<_LogEntry> _buildEntries() {
    final detail = controller.detail;
    if (detail == null) return [];

    final entries = <_LogEntry>[
      ...detail.workItems.map(
        (wi) => _LogEntry(
          date: wi.createdAt,
          author: wi.assignedTo?.trim().isNotEmpty == true
              ? wi.assignedTo!.trim()
              : 'Sistema',
          type: wi.type,
          message: wi.description,
          level: 'info',
        ),
      ),
      ...detail.qualityLogs.map(
        (ql) => _LogEntry(
          date: ql.createdAt,
          author: ql.author,
          type: 'Log',
          message: ql.message,
          level: ql.level.toLowerCase(),
        ),
      ),
    ];

    final order = detail.agentOrder;
    if (order.completedAt != null) {
      entries.add(_LogEntry(
        date: order.completedAt!,
        author: order.completionAuthor?.trim().isNotEmpty == true
            ? order.completionAuthor!.trim()
            : 'Sistema',
        type: 'Estado',
        message: 'Orden finalizada',
        level: 'info',
      ));
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Color _levelColor(String level, CobaltPalette ct) {
    switch (level) {
      case 'info':
        return CobaltColors.cobaltLight;
      case 'warning':
      case 'warn':
        return _kWarning;
      case 'error':
        return _kError;
      default:
        return ct.border;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final entries = _buildEntries();
    final preview = entries.take(50).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Collapsible header row
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  'HISTORIAL DEL SISTEMA',
                  style: TextStyle(
                    color: ct.textHint,
                    fontSize: 9.5,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (entries.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    '${entries.length}',
                    style: TextStyle(
                      color: ct.textHint,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: ct.textHint,
                ),
              ],
            ),
          ),
        ),
        if (!_expanded) const SizedBox.shrink(),
        if (_expanded) ...[
          const SizedBox(height: 6),
          Container(
          height: 34,
          color: ct.surface,
          child: Row(
            children: [
              SizedBox(
                width: 68,
                child: Padding(
                  padding: const EdgeInsets.only(left: 11),
                  child: Text(
                    'Fecha',
                    style: TextStyle(color: ct.textHint, fontSize: 9.5),
                  ),
                ),
              ),
              SizedBox(
                width: 88,
                child: Text(
                  'Usuario',
                  style: TextStyle(color: ct.textHint, fontSize: 9.5),
                ),
              ),
              SizedBox(
                width: 68,
                child: Text(
                  'Acción',
                  style: TextStyle(color: ct.textHint, fontSize: 9.5),
                ),
              ),
              Expanded(
                child: Text(
                  'Mensaje',
                  style: TextStyle(color: ct.textHint, fontSize: 9.5),
                ),
              ),
            ],
          ),
        ),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Sin registros en el log',
              style: TextStyle(color: ct.textHint, fontSize: 12),
            ),
          )
        else ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: preview.length,
              itemBuilder: (context, i) => _EntryRow(
                entry: preview[i],
                borderColor: _levelColor(preview[i].level, ct),
                ct: ct,
              ),
            ),
          ),
          if (entries.length > 50)
            TextButton(
              onPressed: () => _showAllDialog(context, entries),
              child: Text('Ver todos (${entries.length})'),
            ),
        ],
        ], // end if (_expanded)
      ],
    );
  }

  void _showAllDialog(BuildContext context, List<_LogEntry> all) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final dct = ctx.ct;
        return Dialog(
          backgroundColor: dct.background,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'LOG DEL SISTEMA — ${all.length} entradas',
                          style: TextStyle(
                            color: dct.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: dct.textHint, size: 18),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: all.length,
                    itemBuilder: (_, i) => _EntryRow(
                      entry: all[i],
                      borderColor: _levelColor(all[i].level, dct),
                      ct: dct,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.borderColor,
    required this.ct,
  });

  final _LogEntry entry;
  final Color borderColor;
  final CobaltPalette ct;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM HH:mm').format(entry.date);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 30,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: borderColor, width: 3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 68,
                  child: Text(
                    dateStr,
                    style: TextStyle(color: ct.textHint, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 88,
                  child: Text(
                    entry.author,
                    style: TextStyle(color: ct.textSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 68,
                  child: Text(
                    entry.type,
                    style: TextStyle(color: ct.textHint, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.message,
                    style: TextStyle(color: ct.textPrimary, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: ct.border.withValues(alpha: 0.3)),
      ],
    );
  }
}
