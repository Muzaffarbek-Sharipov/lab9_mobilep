import 'package:bloc_test/bloc_test.dart';
import 'package:cart_four_ways/bloc/cart_bloc.dart';
import 'package:cart_four_ways/bloc/cart_event.dart';
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

  blocTest<CartBloc, CartState>(
    'emits one state per event and applies SAVE10',
    build: () => CartBloc(api),
    act: (bloc) {
      bloc
        ..add(CartProductAdded(keyboard))
        ..add(CartProductAdded(keyboard))
        ..add(const CartCouponApplied('SAVE10'));
    },
    expect: () => [
      isA<CartState>().having((s) => s.itemCount, 'itemCount', 1),
      isA<CartState>().having((s) => s.itemCount, 'itemCount', 2),
      isA<CartState>()
          .having((s) => s.coupon, 'coupon', 'SAVE10')
          .having((s) => s.total, 'total', closeTo(88.2, 0.001)),
    ],
  );

  blocTest<CartBloc, CartState>(
    'failed checkout emits submitting then failure',
    setUp: () {
      when(() => api.submit(any())).thenAnswer(
        (_) async => throw const CheckoutException('Card declined'),
      );
    },
    build: () => CartBloc(api),
    seed: () => const CartState().addProduct(keyboard),
    act: (bloc) => bloc.add(const CartCheckoutRequested()),
    expect: () => [
      isA<CartState>().having((s) => s.status, 'status', CheckoutStatus.submitting),
      isA<CartState>()
          .having((s) => s.status, 'status', CheckoutStatus.failure)
          .having((s) => s.checkoutError, 'checkoutError', 'Card declined')
          .having((s) => s.lines, 'lines', isNotEmpty),
    ],
  );

  blocTest<CartBloc, CartState>(
    'droppable drops the second checkout while the first is running',
    setUp: () {
      when(() => api.submit(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return 'ORD-1';
      });
    },
    build: () => CartBloc(api),
    seed: () => const CartState().addProduct(keyboard),
    act: (bloc) {
      bloc
        ..add(const CartCheckoutRequested())
        ..add(const CartCheckoutRequested());
    },
    wait: const Duration(milliseconds: 100),
    expect: () => [
      isA<CartState>().having((s) => s.status, 'status', CheckoutStatus.submitting),
      isA<CartState>()
          .having((s) => s.status, 'status', CheckoutStatus.success)
          .having((s) => s.orderId, 'orderId', 'ORD-1')
          .having((s) => s.lines, 'lines', isEmpty),
    ],
    verify: (_) {
      verify(() => api.submit(any())).called(1);
    },
  );
}
