import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import 'core/colors.dart';
import 'core/cobalt_theme.dart';
import 'core/routes.dart';
import 'core/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initTheme();
  runApp(const CobaltApp());
}

ThemeData _materialTheme(CobaltPalette palette, bool isDark) => ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      useMaterial3: false,
      scaffoldBackgroundColor: palette.background,
      cardColor: palette.surface,
      dividerColor: palette.border,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: CobaltColors.cobalt,
        onPrimary: Colors.white,
        secondary: CobaltColors.cobaltLight,
        onSecondary: Colors.white,
        surface: palette.surface,
        onSurface: palette.textPrimary,
        error: const Color(0xFFCF6679),
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: palette.textPrimary),
        bodySmall: TextStyle(color: palette.textSecondary),
        labelSmall: TextStyle(color: palette.textHint),
      ),
      iconTheme: IconThemeData(color: palette.textSecondary),
      extensions: [palette],
    );

class CobaltApp extends StatelessWidget {
  const CobaltApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS || Platform.isMacOS) {
      return ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, themeMode, _) {
          final isDark = themeMode != ThemeMode.light;
          final palette = isDark ? CobaltPalette.dark : CobaltPalette.light;
          return CupertinoApp.router(
            title: 'ConfigTool Cobalt',
            routerConfig: appRouter,
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultCupertinoLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            theme: CupertinoThemeData(
              brightness: isDark ? Brightness.dark : Brightness.light,
              primaryColor: CobaltColors.cobalt,
              scaffoldBackgroundColor: palette.background,
              textTheme: const CupertinoTextThemeData(
                primaryColor: CobaltColors.cobalt,
              ),
            ),
            builder: (ctx, child) => Theme(
              data: _materialTheme(palette, isDark),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      );
    }

    if (Platform.isWindows) {
      return ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, themeMode, _) {
          final isDark = themeMode != ThemeMode.light;
          final palette = isDark ? CobaltPalette.dark : CobaltPalette.light;
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
            themeMode: themeMode,
            builder: (ctx, child) => Theme(
              data: _materialTheme(palette, isDark),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      );
    }

    // Android — custom Cobalt theme, no Material 3
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp.router(
          title: 'ConfigTool Cobalt',
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter,
          themeMode: themeMode,
          theme: _materialTheme(CobaltPalette.light, false),
          darkTheme: _materialTheme(CobaltPalette.dark, true),
        );
      },
    );
  }
}
