import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import 'cart_event.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc(this._api) : super(const CartState()) {
    on<CartProductAdded>(
      (event, emit) => emit(_record(event, state.addProduct(event.product))),
    );
    on<CartProductRemoved>(
      (event, emit) =>
          emit(_record(event, state.removeProduct(event.productId))),
    );
    on<CartQtyChanged>(
      (event, emit) =>
          emit(_record(event, state.changeQty(event.productId, event.delta))),
    );
    on<CartCouponApplied>(
      (event, emit) => emit(_record(event, state.applyCoupon(event.code))),
    );
    on<CartUndone>(_onUndone);
    on<CartCheckoutRequested>(_onCheckoutRequested, transformer: droppable());
  }

  final CheckoutApi _api;

  CartState _record(CartEvent event, CartState next) =>
      event.isUndoable ? next.recordedFrom(state) : next;

  void _onUndone(CartUndone event, Emitter<CartState> emit) {
    if (!state.canUndo || state.isSubmitting) return;
    emit(state.undone());
  }

  Future<void> _onCheckoutRequested(
    CartCheckoutRequested event,
    Emitter<CartState> emit,
  ) async {
    if (state.lines.isEmpty) return;
    final total = state.total;
    emit(state.submitting());
    try {
      final orderId = await _api.submit(total);
      if (emit.isDone) return;
      emit(state.succeeded(orderId));
    } on CheckoutException catch (e) {
      if (emit.isDone) return;
      emit(state.failed(e.message));
    }
  }
}
