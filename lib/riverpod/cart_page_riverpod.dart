import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../widgets/cart_body.dart';
import '../widgets/cart_summary.dart';
import '../widgets/checkout_feedback.dart';
import 'cart_notifier.dart';

class RiverpodCartPage extends ConsumerWidget {
  const RiverpodCartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(cartProvider.select((s) => s.status), (previous, next) {
      if (next == CheckoutStatus.submitting) {
        hideCheckoutFailure(context);
      } else if (next == CheckoutStatus.success) {
        showOrderConfirmation(context, ref.read(cartProvider).orderId ?? '');
      } else if (next == CheckoutStatus.failure) {
        showCheckoutFailure(
          context,
          ref.read(cartProvider).checkoutError ?? 'Checkout failed',
        );
      }
    });

    final state = ref.watch(cartProvider);
    final canUndo = ref.watch(canUndoProvider);
    final cart = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · Riverpod'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            icon: const Icon(Icons.undo),
            onPressed: canUndo ? cart.undo : null,
          ),
        ],
      ),
      body: CartBody(
        lines: state.lines,
        coupon: state.coupon,
        couponError: state.couponError,
        isSubmitting: state.isSubmitting,
        summary: const _RiverpodSummary(),
        onAdd: cart.add,
        onRemove: cart.remove,
        onQtyChanged: cart.changeQty,
        onApplyCoupon: cart.applyCoupon,
        onCheckout: cart.checkout,
      ),
    );
  }
}

class _RiverpodSummary extends ConsumerWidget {
  const _RiverpodSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(cartProvider.select((s) => s.summary));
    debugPrint('RiverpodSummary rebuilt: total ${summary.total}');
    return CartSummaryCard(summary: summary);
  }
}
