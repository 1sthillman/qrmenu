import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color borderColor;

  const GlassContainer({super.key, required this.child, this.borderRadius = 20, this.borderColor = const Color(0xFF00FFF1)});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor.withOpacity(0.4), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }
} 