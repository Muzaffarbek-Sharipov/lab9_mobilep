import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit(this._api) : super(const CartState());

  final CheckoutApi _api;

  void _commit(CartState next) => emit(next.recordedFrom(state));

  void add(Product p) => _commit(state.addProduct(p));

  void remove(String id) => _commit(state.removeProduct(id));

  void changeQty(String id, int delta) => _commit(state.changeQty(id, delta));

  void applyCoupon(String code) => _commit(state.applyCoupon(code));

  void undo() {
    if (!state.canUndo || state.isSubmitting) return;
    emit(state.undone());
  }

  Future<void> checkout() async {
    if (state.lines.isEmpty || state.isSubmitting) return;
    final total = state.total;
    emit(state.submitting());
    try {
      final orderId = await _api.submit(total);
      if (isClosed) return;
      emit(state.succeeded(orderId));
    } on CheckoutException catch (e) {
      if (isClosed) return;
      emit(state.failed(e.message));
    }
  }
}
