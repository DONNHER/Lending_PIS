// lib/widgets/auth_text_field.dart
import 'package:flutter/material.dart';
import '../app_theme.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool enabled;
  final int? maxLines;
  final int? minLines;

  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused
              ? AppTheme.primary
              : AppTheme.primary.withOpacity(0.3),
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        validator: widget.validator,
        enabled: widget.enabled,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        style: const TextStyle(
          fontSize: 15,
          color: AppTheme.textDark,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,

          // 🚨 Force-remove ALL borders
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,

          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,

          contentPadding: const EdgeInsets.symmetric(vertical: 16),

          labelStyle: TextStyle(
            color: _isFocused ? AppTheme.primary : AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
