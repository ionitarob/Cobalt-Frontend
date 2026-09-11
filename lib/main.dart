import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import 'core/colors.dart';
import 'core/routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CobaltApp());
}

class CobaltApp extends StatelessWidget {
  const CobaltApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS || Platform.isMacOS) {
      return CupertinoApp.router(
        title: 'ConfigTool Cobalt',
        routerConfig: appRouter,
        theme: const CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: CobaltColors.cobalt,
          scaffoldBackgroundColor: CobaltColors.background,
          textTheme: CupertinoTextThemeData(
            primaryColor: CobaltColors.cobalt,
          ),
        ),
      );
    }

    if (Platform.isWindows) {
      return fluent.FluentApp.router(
        title: 'ConfigTool Cobalt',
        routerConfig: appRouter,
        darkTheme: fluent.FluentThemeData(
          brightness: Brightness.dark,
          accentColor: fluent.AccentColor.swatch(const {
            'darkest': Color(0xFF001F5C),
            'darker': Color(0xFF002870),
            'dark': Color(0xFF003280),
            'normal': CobaltColors.cobalt,
            'light': CobaltColors.cobaltLight,
            'lighter': Color(0xFF4D8FE0),
            'lightest': Color(0xFF80B3FF),
          }),
          scaffoldBackgroundColor: CobaltColors.background,
        ),
        themeMode: ThemeMode.dark,
      );
    }

    // Android — custom Cobalt theme, no Material 3
    return MaterialApp.router(
      title: 'ConfigTool Cobalt',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: CobaltColors.cobalt,
          surface: CobaltColors.surface,
        ),
        scaffoldBackgroundColor: CobaltColors.background,
        useMaterial3: false,
      ),
    );
  }
}
