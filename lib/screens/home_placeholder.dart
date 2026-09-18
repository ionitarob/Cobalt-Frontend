import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../core/cobalt_theme.dart';

class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    if (Platform.isIOS || Platform.isMacOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('ConfigTool Cobalt'),
        ),
        child: Center(
          child: Text(
            'Dashboard — coming soon',
            style: TextStyle(color: ct.textSecondary),
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
          content: Center(
            child: Text(
              'Dashboard — coming soon',
              style: TextStyle(color: ct.textSecondary),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: ct.background,
      appBar: AppBar(
        backgroundColor: ct.surface,
        title: Text(
          'ConfigTool Cobalt',
          style: TextStyle(color: ct.textPrimary),
        ),
        iconTheme: IconThemeData(color: ct.textPrimary),
      ),
      body: Center(
        child: Text(
          'Dashboard — coming soon',
          style: TextStyle(color: ct.textSecondary),
        ),
      ),
    );
  }
}
