import 'package:flutter/material.dart';

class CouponField extends StatefulWidget {
  const CouponField({
    super.key,
    required this.applied,
    required this.error,
    required this.enabled,
    required this.onApply,
  });

  final String? applied;
  final String? error;
  final bool enabled;
  final void Function(String code) onApply;

  @override
  State<CouponField> createState() => _CouponFieldState();
}

class _CouponFieldState extends State<CouponField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() => widget.onApply(_controller.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Coupon code',
                  border: const OutlineInputBorder(),
                  errorText: widget.error,
                  helperText:
                      widget.applied == null ? null : 'Applied: ${widget.applied}',
                ),
                onSubmitted: (_) => _apply(),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: FilledButton.tonal(
                onPressed: widget.enabled ? _apply : null,
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      );
}
