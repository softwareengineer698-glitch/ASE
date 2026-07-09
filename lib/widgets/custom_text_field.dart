import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum TextFieldVariant { outlined, filled }

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helperText;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final void Function(String)? onSubmitted;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final TextFieldVariant variant;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final String? counterText;

  const CustomTextField({
    required this.controller, required this.label, super.key,
    this.hint,
    this.helperText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.variant = TextFieldVariant.outlined,
    this.inputFormatters,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.counterText,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _focusAnimation;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _focusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AnimatedBuilder(
      animation: _focusAnimation,
      builder: (context, child) {
        return TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          onFieldSubmitted: widget.onSubmitted,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          focusNode: _focusNode,
          inputFormatters: widget.inputFormatters,
          textCapitalization: widget.textCapitalization,
          autofocus: widget.autofocus,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: widget.enabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.6),
          ),
          decoration: _buildInputDecoration(context, theme, colorScheme),
        );
      },
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final borderRadius = BorderRadius.circular(12);
    
    switch (widget.variant) {
      case TextFieldVariant.outlined:
        return InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          helperText: widget.helperText,
          counterText: widget.counterText,
          prefixIcon: widget.prefixIcon != null 
            ? Icon(
                widget.prefixIcon,
                color: _isFocused 
                  ? colorScheme.primary 
                  : colorScheme.onSurfaceVariant,
              ) 
            : null,
          suffixIcon: widget.suffixIcon,
          
          // Outlined borders
          border: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(
              color: colorScheme.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: colorScheme.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(
              color: colorScheme.error,
              width: 2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
          ),
          
          // Colors and styling
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          
          // Label styling
          labelStyle: WidgetStateTextStyle.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return TextStyle(color: colorScheme.primary);
            }
            if (states.contains(WidgetState.error)) {
              return TextStyle(color: colorScheme.error);
            }
            return TextStyle(color: colorScheme.onSurfaceVariant);
          }),
          
          // Hint styling
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
          
          // Helper text styling
          helperStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        );

      case TextFieldVariant.filled:
        return InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          helperText: widget.helperText,
          counterText: widget.counterText,
          prefixIcon: widget.prefixIcon != null 
            ? Icon(
                widget.prefixIcon,
                color: _isFocused 
                  ? colorScheme.primary 
                  : colorScheme.onSurfaceVariant,
              ) 
            : null,
          suffixIcon: widget.suffixIcon,
          
          // Filled borders
          border: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(
              color: colorScheme.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: colorScheme.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(
              color: colorScheme.error,
              width: 2,
            ),
          ),
          
          // Colors and styling
          filled: true,
          fillColor: widget.enabled 
            ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
            : colorScheme.onSurface.withOpacity(0.04),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          
          // Label styling
          labelStyle: WidgetStateTextStyle.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return TextStyle(color: colorScheme.primary);
            }
            if (states.contains(WidgetState.error)) {
              return TextStyle(color: colorScheme.error);
            }
            return TextStyle(color: colorScheme.onSurfaceVariant);
          }),
          
          // Hint styling
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
          
          // Helper text styling
          helperStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        );
    }
  }
}

/// Specialized search text field
class SearchTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onClear;

  const SearchTextField({
    required this.controller, super.key,
    this.hint = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  @override
  State<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomTextField(
      controller: widget.controller,
      label: '',
      hint: widget.hint,
      prefixIcon: Icons.search,
      variant: TextFieldVariant.filled,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      suffixIcon: widget.controller.text.isNotEmpty
        ? IconButton(
            icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
            onPressed: () {
              widget.controller.clear();
              widget.onClear?.call();
            },
          )
        : null,
    );
  }
}
