import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../core/colors.dart';

class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS || Platform.isMacOS) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('ConfigTool Cobalt'),
        ),
        child: Center(
          child: Text(
            'Dashboard — coming soon',
            style: TextStyle(color: CobaltColors.textSecondary),
          ),
        ),
      );
    }
    if (Platform.isWindows) {
      return fluent.NavigationView(
        content: fluent.ScaffoldPage(
          header: const fluent.PageHeader(
            title: Text('ConfigTool Cobalt'),
          ),
          content: const Center(
            child: Text('Dashboard — coming soon'),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: CobaltColors.background,
      appBar: AppBar(
        backgroundColor: CobaltColors.surface,
        title: const Text(
          'ConfigTool Cobalt',
          style: TextStyle(color: CobaltColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: CobaltColors.textPrimary),
      ),
      body: const Center(
        child: Text(
          'Dashboard — coming soon',
          style: TextStyle(color: CobaltColors.textSecondary),
        ),
      ),
    );
  }
}
