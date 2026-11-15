import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import '../widgets/cart_summary.dart';
import '../widgets/checkout_feedback.dart';

class SetStateCartPage extends StatefulWidget {
  const SetStateCartPage({super.key, this.api = const CheckoutApi()});

  final CheckoutApi api;

  @override
  State<SetStateCartPage> createState() => _SetStateCartPageState();
}

class _SetStateCartPageState extends State<SetStateCartPage> {
  CartState _state = const CartState();
  final List<CartState> _history = [];

  bool get _canUndo => _history.isNotEmpty && !_state.isSubmitting;

  void _commit(CartState next) {
    if (next == _state) return;
    setState(() {
      _history.add(_state);
      _state = next;
    });
  }

  void _add(Product p) => _commit(_state.addProduct(p));

  void _remove(String id) => _commit(_state.removeProduct(id));

  void _changeQty(String id, int delta) => _commit(_state.changeQty(id, delta));

  void _applyCoupon(String code) => _commit(_state.applyCoupon(code));

  void _undo() {
    if (!_canUndo) return;
    setState(() => _state = _state.restoring(_history.removeLast()));
  }

  Future<void> _checkout() async {
    if (_state.lines.isEmpty || _state.isSubmitting) return;
    final total = _state.total;
    hideCheckoutFailure(context);
    setState(() => _state = _state.submitting());
    try {
      final orderId = await widget.api.submit(total);
      if (!mounted) return;
      setState(() {
        _history.clear();
        _state = _state.succeeded(orderId);
      });
      showOrderConfirmation(context, orderId);
    } on CheckoutException catch (e) {
      if (!mounted) return;
      setState(() => _state = _state.failed(e.message));
      showCheckoutFailure(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Cart · setState'),
          actions: [
            IconButton(
              tooltip: 'Undo',
              icon: const Icon(Icons.undo),
              onPressed: _canUndo ? _undo : null,
            ),
          ],
        ),
        body: CartBody(
          lines: _state.lines,
          coupon: _state.coupon,
          couponError: _state.couponError,
          isSubmitting: _state.isSubmitting,
          summary: CartSummaryCard(summary: _state.summary),
          onAdd: _add,
          onRemove: _remove,
          onQtyChanged: _changeQty,
          onApplyCoupon: _applyCoupon,
          onCheckout: _checkout,
        ),
      );
}
