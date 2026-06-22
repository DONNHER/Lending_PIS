import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
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
  final int? maxLength;

  const AuthTextField({
    super.key,
    required this.label,
    this.controller,
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
    this.maxLength,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  TextEditingController? _internalController;
  late FocusNode _focusNode;
  bool _isFocused = false;

  TextEditingController get _effectiveController => widget.controller ?? (_internalController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _isFocused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: widget.validator,
      initialValue: _effectiveController.text,
      builder: (FormFieldState<String> fieldState) {
        final bool hasError = fieldState.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasError
                      ? AppTheme.error
                      : _isFocused
                          ? AppTheme.primary
                          : AppTheme.primary.withOpacity(0.3),
                  width: _isFocused || hasError ? 2 : 1,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: (hasError ? AppTheme.error : AppTheme.primary)
                              .withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: TextField(
                controller: _effectiveController,
                focusNode: _focusNode,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                onChanged: (value) {
                  fieldState.didChange(value);
                  if (widget.onChanged != null) widget.onChanged!(value);
                },
                onSubmitted: widget.onSubmitted,
                enabled: widget.enabled,
                maxLines: widget.maxLines,
                minLines: widget.minLines,
                maxLength: widget.maxLength,
                maxLengthEnforcement: widget.maxLength != null ? MaxLengthEnforcement.enforced : null,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  counterText: "", 
                  labelText: widget.label,
                  hintText: widget.hint,
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
                    color: hasError
                        ? AppTheme.error
                        : _isFocused
                            ? AppTheme.primary
                            : AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 6),
                child: Text(
                  fieldState.errorText!,
                  style: const TextStyle(
                    color: AppTheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
