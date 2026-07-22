import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:study_voice_ai/core/theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double borderOpacity;
  final double backgroundOpacity;
  final LinearGradient? borderGradient;

  const GlassCard({
    Key? key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 15.0,
    this.padding = const EdgeInsets.all(20.0),
    this.color,
    this.borderOpacity = 0.15,
    this.backgroundOpacity = 0.08,
    this.borderGradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = color ?? (isDark ? Colors.white : Colors.black);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: baseColor.withOpacity(isDark ? backgroundOpacity : 0.05),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: baseColor.withOpacity(borderOpacity),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
