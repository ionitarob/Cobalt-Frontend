import 'package:flutter/material.dart';

import '../../core/cobalt_theme.dart';
import '../../core/colors.dart';
import '../../core/nav_items.dart';

class AreaPlaceholder extends StatelessWidget {
  final String title;
  final IconData icon;

  const AreaPlaceholder({
    super.key,
    required this.title,
    required this.icon,
  });

  factory AreaPlaceholder.fromItem(NavItem item) => AreaPlaceholder(
        key: ValueKey(item.route),
        title: item.label,
        icon: item.icon,
      );

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Material(
      color: ct.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle radial glow centred behind the icon
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CobaltColors.cobalt.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon container
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: ct.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ct.border,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: CobaltColors.cobalt.withValues(alpha: 0.08),
                        blurRadius: 32,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: ct.textHint,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    color: ct.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CobaltColors.cobaltLight.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'En construcción',
                      style: TextStyle(
                        color: ct.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CobaltColors.cobaltLight.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
