import 'package:flutter/material.dart';

class OTPInput extends StatefulWidget {
  final bool enabled;

  const OTPInput({super.key, required this.enabled});

  @override
  State<OTPInput> createState() => _OTPInputState();
}

class _OTPInputState extends State<OTPInput> {
  final _controllers =
      List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 42,
          child: TextField(
            controller: _controllers[i],
            focusNode: _focusNodes[i],
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            decoration: const InputDecoration(
              counterText: '',
            ),
            onChanged: (v) {
              if (v.isNotEmpty && i < 5) {
                _focusNodes[i + 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }
}