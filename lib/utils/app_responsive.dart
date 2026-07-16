import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppResponsive {
  const AppResponsive._();

  static const Size designSize = Size(375, 812);
  static const double minScale = 0.95;
  static const double maxScale = 1.14;

  static double clampedFontSize(num fontSize, ScreenUtil instance) {
    return fontSize * _clampedTextScale(instance);
  }

  static TextTheme scaleTextTheme(TextTheme textTheme) {
    return textTheme.copyWith(
      displayLarge: _scaleStyle(textTheme.displayLarge),
      displayMedium: _scaleStyle(textTheme.displayMedium),
      displaySmall: _scaleStyle(textTheme.displaySmall),
      headlineLarge: _scaleStyle(textTheme.headlineLarge),
      headlineMedium: _scaleStyle(textTheme.headlineMedium),
      headlineSmall: _scaleStyle(textTheme.headlineSmall),
      titleLarge: _scaleStyle(textTheme.titleLarge),
      titleMedium: _scaleStyle(textTheme.titleMedium),
      titleSmall: _scaleStyle(textTheme.titleSmall),
      bodyLarge: _scaleStyle(textTheme.bodyLarge),
      bodyMedium: _scaleStyle(textTheme.bodyMedium),
      bodySmall: _scaleStyle(textTheme.bodySmall),
      labelLarge: _scaleStyle(textTheme.labelLarge),
      labelMedium: _scaleStyle(textTheme.labelMedium),
      labelSmall: _scaleStyle(textTheme.labelSmall),
    );
  }

  static TextStyle? _scaleStyle(TextStyle? style) {
    final fontSize = style?.fontSize;
    if (style == null || fontSize == null) return style;
    return style.copyWith(fontSize: fontSize.sp);
  }

  static double _clampedTextScale(ScreenUtil instance) {
    final shortestAxisScale = instance.scaleWidth < instance.scaleHeight
        ? instance.scaleWidth
        : instance.scaleHeight;

    return shortestAxisScale.clamp(minScale, maxScale).toDouble();
  }
}
