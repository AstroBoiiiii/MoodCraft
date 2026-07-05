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

  // Derived tones: secondary text/icons sit a step softer than onSurface, and
  // outlines stay faint so nothing reads as a hard edge (CLAUDE.md section 4).
  final onSurfaceVariant = Color.alphaBlend(
    p.onSurface.withValues(alpha: 0.72),
    p.surface,
  );
  final outline = Color.alphaBlend(
    p.onSurface.withValues(alpha: 0.40),
    p.surface,
  );
  final outlineVariant = Color.alphaBlend(
    p.onSurface.withValues(alpha: 0.16),
    p.surface,
  );

  final scheme = ColorScheme(
    brightness: p.brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    primaryContainer: p.accent,
    onPrimaryContainer: p.onSurface,
    secondary: p.secondary,
    onSecondary: p.onSurface,
    secondaryContainer: p.accent,
    onSecondaryContainer: p.onSurface,
    error: kMutedAlert,
    onError: Colors.white,
    surface: p.surface,
    onSurface: p.onSurface,
    onSurfaceVariant: onSurfaceVariant,
    surfaceContainerLow: p.surface,
    surfaceContainerHigh: p.surfaceHigh,
    surfaceContainerHighest: p.surfaceHigh,
    outline: outline,
    outlineVariant: outlineVariant,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    colorScheme: scheme,
    visualDensity: VisualDensity.comfortable,
  );

  InputBorder fieldBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        borderSide: BorderSide(color: color, width: width),
      );

  return base.copyWith(
    scaffoldBackgroundColor: p.background,
    textTheme: _calmTextTheme(base.textTheme, p.onSurface),
    // No scroll-under tint or elevation change — the app bar never shifts
    // colour mid-scroll (predictable, no surprise motion).
    appBarTheme: AppBarTheme(
      backgroundColor: p.surface,
      foregroundColor: p.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
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
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
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
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.primary,
        side: BorderSide(color: p.primary.withValues(alpha: 0.55)),
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.primary,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.primary,
      foregroundColor: p.onPrimary,
      elevation: 1,
      focusElevation: 1,
      hoverElevation: 2,
      highlightElevation: 1,
      extendedTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    // Soft filled fields with a faint outline, so a field reads the same on
    // the scaffold background, inside a card, and inside a sheet.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surfaceHigh.withValues(alpha: 0.45),
      prefixIconColor: onSurfaceVariant,
      suffixIconColor: onSurfaceVariant,
      labelStyle: TextStyle(color: onSurfaceVariant),
      hintStyle: TextStyle(color: onSurfaceVariant.withValues(alpha: 0.75)),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: fieldBorder(outlineVariant),
      enabledBorder: fieldBorder(outlineVariant),
      focusedBorder: fieldBorder(p.primary, 1.8),
      errorBorder: fieldBorder(kMutedAlert),
      focusedErrorBorder: fieldBorder(kMutedAlert, 1.8),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: BorderSide(color: outlineVariant.withValues(alpha: 0.7)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: onSurfaceVariant,
      selectedTileColor: p.accent.withValues(alpha: 0.28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    dividerTheme: DividerThemeData(color: outlineVariant, thickness: 1),
    chipTheme: ChipThemeData(
      backgroundColor: p.surface,
      selectedColor: p.accent,
      side: BorderSide(color: outlineVariant),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(color: p.onSurface, fontSize: 15),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      titleTextStyle: TextStyle(
        color: p.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(
        color: p.onSurface,
        fontSize: 16,
        height: 1.3,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      modalBackgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.onSurface,
      contentTextStyle: TextStyle(color: p.surface, fontSize: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(color: p.onSurface, fontSize: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.primary,
      linearTrackColor: p.surfaceHigh,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        side: BorderSide(color: outlineVariant),
        selectedBackgroundColor: p.accent,
        selectedForegroundColor: p.onSurface,
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
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.accent,
      selectedIconTheme: IconThemeData(color: p.onSurface),
      unselectedIconTheme: IconThemeData(color: onSurfaceVariant),
      selectedLabelTextStyle: TextStyle(
        fontSize: 13,
        color: p.onSurface,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: TextStyle(
        fontSize: 13,
        color: onSurfaceVariant,
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
