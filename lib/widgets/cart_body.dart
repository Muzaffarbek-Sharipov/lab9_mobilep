import 'package:flutter/material.dart';

import '../models/cart.dart';
import 'coupon_field.dart';

class CartBody extends StatelessWidget {
  const CartBody({
    super.key,
    required this.lines,
    required this.coupon,
    required this.couponError,
    required this.isSubmitting,
    required this.summary,
    required this.onAdd,
    required this.onRemove,
    required this.onQtyChanged,
    required this.onApplyCoupon,
    required this.onCheckout,
  });

  final List<CartLine> lines;
  final String? coupon;
  final String? couponError;
  final bool isSubmitting;
  final Widget summary;
  final void Function(Product) onAdd;
  final void Function(String productId) onRemove;
  final void Function(String productId, int delta) onQtyChanged;
  final void Function(String code) onApplyCoupon;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                for (final p in catalog)
                  ActionChip(
                    label: Text('${p.name} · ${p.price.toStringAsFixed(0)}'),
                    onPressed: isSubmitting ? null : () => onAdd(p),
                  ),
              ],
            ),
          ),
          if (lines.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Cart is empty')),
            )
          else
            for (final l in lines)
              Dismissible(
                key: ValueKey(l.product.id),
                direction: isSubmitting
                    ? DismissDirection.none
                    : DismissDirection.endToStart,
                background: Container(
                  color: Theme.of(context).colorScheme.errorContainer,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete_outline),
                ),
                onDismissed: (_) => onRemove(l.product.id),
                child: ListTile(
                  title: Text(l.product.name),
                  subtitle: Text(l.subtotal.toStringAsFixed(2)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Decrease',
                        icon: const Icon(Icons.remove),
                        onPressed: isSubmitting
                            ? null
                            : () => onQtyChanged(l.product.id, -1),
                      ),
                      Text('${l.qty}'),
                      IconButton(
                        tooltip: 'Increase',
                        icon: const Icon(Icons.add),
                        onPressed: isSubmitting
                            ? null
                            : () => onQtyChanged(l.product.id, 1),
                      ),
                    ],
                  ),
                ),
              ),
          CouponField(
            applied: coupon,
            error: couponError,
            enabled: !isSubmitting,
            onApply: onApplyCoupon,
          ),
          summary,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FilledButton(
              onPressed: lines.isEmpty || isSubmitting ? null : onCheckout,
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Checkout'),
            ),
          ),
        ],
      );
}
