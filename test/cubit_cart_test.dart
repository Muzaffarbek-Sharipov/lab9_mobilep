import 'package:bloc_test/bloc_test.dart';
import 'package:cart_four_ways/cubit/cart_cubit.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

final keyboard = catalog.first;

void main() {
  late MockCheckoutApi api;

  setUpAll(() => registerFallbackValue(0.0));

  setUp(() => api = MockCheckoutApi());

  blocTest<CartCubit, CartState>(
    'emits one state per mutation and applies SAVE10',
    build: () => CartCubit(api),
    act: (cubit) {
      cubit
        ..add(keyboard)
        ..add(keyboard)
        ..applyCoupon('SAVE10');
    },
    expect: () => [
      isA<CartState>().having((s) => s.itemCount, 'itemCount', 1),
      isA<CartState>().having((s) => s.itemCount, 'itemCount', 2),
      isA<CartState>()
          .having((s) => s.coupon, 'coupon', 'SAVE10')
          .having((s) => s.total, 'total', closeTo(88.2, 0.001)),
    ],
  );

  blocTest<CartCubit, CartState>(
    'failed checkout emits submitting then failure',
    setUp: () {
      when(() => api.submit(any())).thenAnswer(
        (_) async => throw const CheckoutException('Card declined'),
      );
    },
    build: () => CartCubit(api),
    seed: () => const CartState().addProduct(keyboard),
    act: (cubit) => cubit.checkout(),
    expect: () => [
      isA<CartState>().having((s) => s.status, 'status', CheckoutStatus.submitting),
      isA<CartState>()
          .having((s) => s.status, 'status', CheckoutStatus.failure)
          .having((s) => s.checkoutError, 'checkoutError', 'Card declined')
          .having((s) => s.lines, 'lines', isNotEmpty),
    ],
  );
}
