import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import '../widgets/cart_summary.dart';
import '../widgets/checkout_feedback.dart';
import 'cart_bloc.dart';
import 'cart_event.dart';

class BlocCartPage extends StatelessWidget {
  const BlocCartPage({super.key, this.api = const CheckoutApi()});

  final CheckoutApi api;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => CartBloc(api),
        child: const _BlocCartView(),
      );
}

class _BlocCartView extends StatelessWidget {
  const _BlocCartView();

  @override
  Widget build(BuildContext context) =>
      BlocListener<CartBloc, CartState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          switch (state.status) {
            case CheckoutStatus.submitting:
              hideCheckoutFailure(context);
            case CheckoutStatus.success:
              showOrderConfirmation(context, state.orderId ?? '');
            case CheckoutStatus.failure:
              showCheckoutFailure(
                context,
                state.checkoutError ?? 'Checkout failed',
              );
            case CheckoutStatus.idle:
              break;
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Cart · Bloc'),
            actions: [
              BlocSelector<CartBloc, CartState, bool>(
                selector: (state) => state.canUndo && !state.isSubmitting,
                builder: (context, enabled) => IconButton(
                  tooltip: 'Undo',
                  icon: const Icon(Icons.undo),
                  onPressed: enabled
                      ? () => context.read<CartBloc>().add(const CartUndone())
                      : null,
                ),
              ),
            ],
          ),
          body: BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              final bloc = context.read<CartBloc>();
              return CartBody(
                lines: state.lines,
                coupon: state.coupon,
                couponError: state.couponError,
                isSubmitting: state.isSubmitting,
                summary: const _BlocSummary(),
                onAdd: (p) => bloc.add(CartProductAdded(p)),
                onRemove: (id) => bloc.add(CartProductRemoved(id)),
                onQtyChanged: (id, delta) => bloc.add(CartQtyChanged(id, delta)),
                onApplyCoupon: (code) => bloc.add(CartCouponApplied(code)),
                onCheckout: () => bloc.add(const CartCheckoutRequested()),
              );
            },
          ),
        ),
      );
}

class _BlocSummary extends StatelessWidget {
  const _BlocSummary();

  @override
  Widget build(BuildContext context) =>
      BlocSelector<CartBloc, CartState, CartSummary>(
        selector: (state) => state.summary,
        builder: (context, summary) {
          debugPrint('BlocSummary rebuilt: total ${summary.total}');
          return CartSummaryCard(summary: summary);
        },
      );
}
