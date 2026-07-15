import 'dart:math';
import 'package:flutter/material.dart';
import '../app_theme.dart';

class MathCaptcha extends StatefulWidget {
  final ValueChanged<bool> onVerified;
  const MathCaptcha({super.key, required this.onVerified});

  @override
  State<MathCaptcha> createState() => _MathCaptchaState();
}

class _MathCaptchaState extends State<MathCaptcha> {
  late int _num1;
  late int _num2;
  late int _result;
  final TextEditingController _controller = TextEditingController();
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  void _generateCaptcha() {
    final random = Random();
    _num1 = random.nextInt(10) + 1;
    _num2 = random.nextInt(10) + 1;
    _result = _num1 + _num2;
    _controller.clear();
    _isVerified = false;
    widget.onVerified(false);
  }

  void _checkResult(String value) {
    final intValue = int.tryParse(value);
    if (intValue == _result) {
      setState(() {
        _isVerified = true;
      });
      widget.onVerified(true);
    } else {
      if (_isVerified) {
        setState(() {
          _isVerified = false;
        });
        widget.onVerified(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isVerified ? Colors.green : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security_rounded, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              const Text(
                'Security Check',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18, color: AppTheme.textMuted),
                onPressed: _generateCaptcha,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  '$_num1 + $_num2 = ',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppTheme.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  onChanged: _checkResult,
                  decoration: InputDecoration(
                    hintText: '?',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    fillColor: Colors.white,
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _isVerified ? Colors.green : AppTheme.primary),
                    ),
                  ),
                ),
              ),
              if (_isVerified)
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
