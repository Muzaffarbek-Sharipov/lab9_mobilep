import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import '../widgets/cart_summary.dart';
import '../widgets/checkout_feedback.dart';
import 'cart_cubit.dart';

class CubitCartPage extends StatelessWidget {
  const CubitCartPage({super.key, this.api = const CheckoutApi()});

  final CheckoutApi api;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => CartCubit(api),
        child: const _CubitCartView(),
      );
}

class _CubitCartView extends StatelessWidget {
  const _CubitCartView();

  @override
  Widget build(BuildContext context) =>
      BlocListener<CartCubit, CartState>(
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
            title: const Text('Cart · Cubit'),
            actions: [
              BlocSelector<CartCubit, CartState, bool>(
                selector: (state) => state.canUndo && !state.isSubmitting,
                builder: (context, enabled) => IconButton(
                  tooltip: 'Undo',
                  icon: const Icon(Icons.undo),
                  onPressed: enabled ? context.read<CartCubit>().undo : null,
                ),
              ),
            ],
          ),
          body: BlocBuilder<CartCubit, CartState>(
            builder: (context, state) {
              final cart = context.read<CartCubit>();
              return CartBody(
                lines: state.lines,
                coupon: state.coupon,
                couponError: state.couponError,
                isSubmitting: state.isSubmitting,
                summary: const _CubitSummary(),
                onAdd: cart.add,
                onRemove: cart.remove,
                onQtyChanged: cart.changeQty,
                onApplyCoupon: cart.applyCoupon,
                onCheckout: cart.checkout,
              );
            },
          ),
        ),
      );
}

class _CubitSummary extends StatelessWidget {
  const _CubitSummary();

  @override
  Widget build(BuildContext context) =>
      BlocSelector<CartCubit, CartState, CartSummary>(
        selector: (state) => state.summary,
        builder: (context, summary) {
          debugPrint('CubitSummary rebuilt: total ${summary.total}');
          return CartSummaryCard(summary: summary);
        },
      );
}
