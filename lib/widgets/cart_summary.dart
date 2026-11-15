import 'package:flutter/material.dart';

import '../models/cart.dart';

class CartSummaryCard extends StatelessWidget {
  const CartSummaryCard({super.key, required this.summary});

  final CartSummary summary;

  @override
  Widget build(BuildContext context) {
    final discount = summary.discount == 0
        ? '0.00'
        : '-${summary.discount.toStringAsFixed(2)}';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SummaryRow(label: 'Items', value: '${summary.itemCount}'),
            _SummaryRow(
              label: 'Subtotal',
              value: summary.subtotal.toStringAsFixed(2),
            ),
            _SummaryRow(label: 'Discount', value: discount),
            const Divider(),
            _SummaryRow(
              label: 'Total',
              value: summary.total.toStringAsFixed(2),
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
