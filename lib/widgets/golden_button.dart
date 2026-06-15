import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

class GoldenButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const GoldenButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height = 55,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed != null ? AppColors.buttonGradient : null,
        color: onPressed == null ? Colors.grey : null,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: onPressed != null ? [
          BoxShadow(
            color: AppColors.goldBase.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
        ),
        child: child,
      ),
    );
  }
}
