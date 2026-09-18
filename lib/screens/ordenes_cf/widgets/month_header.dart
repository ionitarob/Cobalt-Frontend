import 'package:flutter/material.dart';

import '../../../core/cobalt_theme.dart';

class MonthHeader extends StatelessWidget {
  final String month;
  const MonthHeader({super.key, required this.month});

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Text(
            month,
            style: TextStyle(
              color: ct.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(height: 1, color: ct.border),
          ),
        ],
      ),
    );
  }
}
