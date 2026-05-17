import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_motion.dart';

enum CpButtonVariant { primary, secondary, outlined, ghost, danger, accept }

/// CampusPool button — brutalist, tactile press animation.
class CpButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final CpButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  const CpButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = CpButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  @override
  State<CpButton> createState() => _CpButtonState();
}

class _CpButtonState extends State<CpButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: AppMotion.instant, vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _bgColor {
    switch (widget.variant) {
      case CpButtonVariant.primary: return AppColors.signalYellow;
      case CpButtonVariant.secondary: return AppColors.surface2;
      case CpButtonVariant.outlined: return Colors.transparent;
      case CpButtonVariant.ghost: return Colors.transparent;
      case CpButtonVariant.danger: return AppColors.rejectRed;
      case CpButtonVariant.accept: return AppColors.acceptGreen;
    }
  }

  Color get _textColor {
    switch (widget.variant) {
      case CpButtonVariant.primary: return AppColors.systemBlack;
      case CpButtonVariant.secondary: return AppColors.textPrimary;
      case CpButtonVariant.outlined: return AppColors.textPrimary;
      case CpButtonVariant.ghost: return AppColors.textSecondary;
      case CpButtonVariant.danger: return AppColors.pureWhite;
      case CpButtonVariant.accept: return AppColors.systemBlack;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          height: AppConstants.buttonHeight,
          child: Material(
            color: _bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
              side: widget.variant == CpButtonVariant.outlined
                  ? const BorderSide(color: AppColors.borderSubtle, width: 2)
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: _textColor,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: _textColor, size: 18),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              color: _textColor,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
