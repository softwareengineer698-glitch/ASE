import 'package:flutter/material.dart';

enum ButtonVariant { filled, outlined, text, tonal }

enum ButtonSize { small, medium, large }

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double? borderRadius;
  final IconData? icon;
  final IconData? trailingIcon;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool fullWidth;
  final String? tooltip;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius,
    this.icon,
    this.trailingIcon,
    this.variant = ButtonVariant.filled,
    this.size = ButtonSize.medium,
    this.fullWidth = false,
    this.tooltip,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double get _buttonHeight {
    switch (widget.size) {
      case ButtonSize.small:
        return 40;
      case ButtonSize.medium:
        return 48;
      case ButtonSize.large:
        return 56;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 18;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case ButtonSize.small:
        return 18;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget button = _buildButton(context, theme, colorScheme);

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: button,
        );
      },
    );
  }

  Widget _buildButton(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final width = widget.fullWidth ? double.infinity : widget.width;
    final height = widget.height ?? _buttonHeight;
    final borderRadius = widget.borderRadius ?? 12.0;

    return SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
        onTapDown:
            widget.onPressed != null && !widget.isLoading ? _onTapDown : null,
        onTapUp:
            widget.onPressed != null && !widget.isLoading ? _onTapUp : null,
        onTapCancel:
            widget.onPressed != null && !widget.isLoading ? _onTapCancel : null,
        child: _buildButtonByVariant(context, theme, colorScheme, borderRadius),
      ),
    );
  }

  Widget _buildButtonByVariant(BuildContext context, ThemeData theme,
      ColorScheme colorScheme, double borderRadius) {
    final buttonChild = _buildButtonContent(colorScheme);

    switch (widget.variant) {
      case ButtonVariant.filled:
        return ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.backgroundColor ?? colorScheme.primary,
            foregroundColor: widget.textColor ?? colorScheme.onPrimary,
            disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
            disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            elevation: 1,
            shadowColor: colorScheme.shadow,
            padding: EdgeInsets.symmetric(
              horizontal: widget.size == ButtonSize.small ? 16 : 24,
              vertical: 0,
            ),
          ),
          child: buttonChild,
        );

      case ButtonVariant.outlined:
        return OutlinedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: widget.textColor ?? colorScheme.primary,
            disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
            side: BorderSide(
              color: widget.backgroundColor ?? colorScheme.outline,
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.size == ButtonSize.small ? 16 : 24,
              vertical: 0,
            ),
          ),
          child: buttonChild,
        );

      case ButtonVariant.text:
        return TextButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: TextButton.styleFrom(
            foregroundColor: widget.textColor ?? colorScheme.primary,
            disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.size == ButtonSize.small ? 12 : 16,
              vertical: 0,
            ),
          ),
          child: buttonChild,
        );

      case ButtonVariant.tonal:
        return FilledButton.tonal(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: FilledButton.styleFrom(
            backgroundColor:
                widget.backgroundColor ?? colorScheme.secondaryContainer,
            foregroundColor:
                widget.textColor ?? colorScheme.onSecondaryContainer,
            disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
            disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            elevation: 0,
            padding: EdgeInsets.symmetric(
              horizontal: widget.size == ButtonSize.small ? 16 : 24,
              vertical: 0,
            ),
          ),
          child: buttonChild,
        );
    }
  }

  Widget _buildButtonContent(ColorScheme colorScheme) {
    if (widget.isLoading) {
      return SizedBox(
        width: _iconSize,
        height: _iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.variant == ButtonVariant.filled
                ? colorScheme.onPrimary
                : colorScheme.primary,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: _iconSize),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(widget.trailingIcon, size: _iconSize),
        ],
      ],
    );
  }
}
