import 'package:flutter/material.dart';

import '../../../core/cobalt_theme.dart';
import '../../../core/colors.dart';
import 'status_badge.dart';

class FilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedEstado;
  final bool filterByMe;
  final ValueChanged<String?> onEstadoChanged;
  final ValueChanged<bool> onFilterByMeChanged;
  final VoidCallback onSearchChanged;

  const FilterBar({
    super.key,
    required this.searchController,
    required this.selectedEstado,
    required this.filterByMe,
    required this.onEstadoChanged,
    required this.onFilterByMeChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Single row: chips (left, scrollable) + search (right, capped)
        SizedBox(
          height: 32,
          child: Row(
            children: [
              // Chips — scrollable, fills available space
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _Chip(
                        label: 'Todas',
                        selected: selectedEstado == null && !filterByMe,
                        color: CobaltColors.cobaltLight,
                        onTap: () {
                          onEstadoChanged(null);
                          onFilterByMeChanged(false);
                        },
                      ),
                      const SizedBox(width: 6),
                      for (final code in ['1', '2', '3', '4', '5', '6'])
                        Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _Chip(
                              label: StatusBadge.labelFor(code),
                              dotColor: StatusBadge.colorFor(code),
                              selected: selectedEstado != null &&
                                  selectedEstado!.contains(code),
                              color: StatusBadge.colorFor(code),
                              onTap: () => onEstadoChanged(
                                  (selectedEstado != null &&
                                          selectedEstado!.contains(code))
                                      ? null
                                      : code),
                            ),
                          ),
                      Container(
                        width: 1,
                        height: 16,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: ct.border,
                      ),
                      _Chip(
                        label: 'Mis órdenes',
                        selected: filterByMe,
                        color: CobaltColors.cobaltLight,
                        onTap: () => onFilterByMeChanged(!filterByMe),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Search — fixed 240px
              SizedBox(
                width: 240,
                child: TextField(
                  controller: searchController,
                  onChanged: (_) => onSearchChanged(),
                  style: TextStyle(color: ct.textPrimary, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Buscar orden, cliente…',
                    hintStyle: TextStyle(color: ct.textHint, fontSize: 12),
                    prefixIcon: Icon(Icons.search_rounded,
                        size: 14, color: ct.textHint),
                    filled: true,
                    fillColor: ct.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: ct.border, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: ct.border, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                          color: CobaltColors.cobaltLight, width: 1),
                    ),
                    contentPadding: EdgeInsets.zero,
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                size: 12, color: ct.textHint),
                            onPressed: () {
                              searchController.clear();
                              onSearchChanged();
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final Color? dotColor;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.color,
    this.dotColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.50)
                  : ct.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                    width: 5, height: 5,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? dotColor!
                            : dotColor!.withValues(alpha: 0.45))),
                const SizedBox(width: 5),
              ],
              Text(label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? color
                        : ct.textHint,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
