/// Builds a [ThemeData] from the current [SensorySettings] so every activity
/// inherits the chosen calm palette and the animation-intensity preference
/// (CLAUDE.md sections 3, 4, 8).
library;

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/enums.dart';
import '../../core/models/sensory_settings.dart';
import 'palettes.dart';
import 'tokens.dart';

ThemeData buildTheme(SensorySettings settings) {
  final p = paletteFor(settings.colorTheme);

  final scheme = ColorScheme(
    brightness: p.brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    secondary: p.secondary,
    onSecondary: p.onSurface,
    error: kMutedAlert,
    onError: Colors.white,
    surface: p.surface,
    onSurface: p.onSurface,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    colorScheme: scheme,
    visualDensity: VisualDensity.comfortable,
  );

  return base.copyWith(
    scaffoldBackgroundColor: p.background,
    textTheme: _calmTextTheme(base.textTheme, p.onSurface),
    appBarTheme: AppBarTheme(
      backgroundColor: p.surface,
      foregroundColor: p.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: p.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        elevation: 0,
        minimumSize: const Size(
          AppConstants.minTapTarget,
          AppConstants.minTapTarget,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.accent,
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 14,
          color: p.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    // When animation is switched off, route changes are instant (no transition).
    pageTransitionsTheme:
        settings.animationIntensity == AnimationIntensity.off
            ? const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: _NoTransitionsBuilder(),
                TargetPlatform.iOS: _NoTransitionsBuilder(),
                TargetPlatform.linux: _NoTransitionsBuilder(),
                TargetPlatform.macOS: _NoTransitionsBuilder(),
                TargetPlatform.windows: _NoTransitionsBuilder(),
                TargetPlatform.fuchsia: _NoTransitionsBuilder(),
              },
            )
            : const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
              },
            ),
  );
}

TextTheme _calmTextTheme(TextTheme base, Color onSurface) {
  TextStyle? s(TextStyle? style, double size, FontWeight weight) =>
      style?.copyWith(
        fontSize: size,
        fontWeight: weight,
        color: onSurface,
        height: 1.3,
      );
  return base.copyWith(
    displaySmall: s(base.displaySmall, 32, FontWeight.w600),
    headlineMedium: s(base.headlineMedium, 28, FontWeight.w600),
    headlineSmall: s(base.headlineSmall, 24, FontWeight.w600),
    titleLarge: s(base.titleLarge, 22, FontWeight.w600),
    bodyLarge: s(base.bodyLarge, 18, FontWeight.w400),
    bodyMedium: s(base.bodyMedium, 16, FontWeight.w400),
    labelLarge: s(base.labelLarge, 18, FontWeight.w600),
  );
}

/// Instant page transition used when animations are turned off.
class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
