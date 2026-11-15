import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';

final checkoutApiProvider = Provider<CheckoutApi>((ref) => const CheckoutApi());

class CartNotifier extends Notifier<CartState> {
  final List<CartState> _history = [];

  @override
  CartState build() {
    _history.clear();
    return const CartState();
  }

  bool get canUndo => _history.isNotEmpty && !state.isSubmitting;

  void _commit(CartState next) {
    if (next == state) return;
    _history.add(state);
    state = next;
  }

  void add(Product p) => _commit(state.addProduct(p));

  void remove(String id) => _commit(state.removeProduct(id));

  void changeQty(String id, int delta) => _commit(state.changeQty(id, delta));

  void applyCoupon(String code) => _commit(state.applyCoupon(code));

  void undo() {
    if (!canUndo) return;
    state = state.restoring(_history.removeLast());
  }

  Future<void> checkout() async {
    if (state.lines.isEmpty || state.isSubmitting) return;
    final total = state.total;
    state = state.submitting();
    try {
      final orderId = await ref.read(checkoutApiProvider).submit(total);
      _history.clear();
      state = state.succeeded(orderId);
    } on CheckoutException catch (e) {
      state = state.failed(e.message);
    }
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);

final canUndoProvider = Provider<bool>((ref) {
  ref.watch(cartProvider);
  return ref.read(cartProvider.notifier).canUndo;
});
