import 'package:cart_four_ways/models/cart.dart';
import 'package:flutter_test/flutter_test.dart';

final keyboard = catalog[0];
final mouse = catalog[1];

void main() {
  test('withProduct adds a line and then increments it', () {
    final once = const <CartLine>[].withProduct(keyboard);
    final twice = once.withProduct(keyboard);

    expect(once.single.qty, 1);
    expect(twice.single.qty, 2);
    expect(identical(once, twice), isFalse);
  });

  test('changeQty decrements and removes the line at zero', () {
    final lines = const <CartLine>[].withProduct(keyboard).withProduct(keyboard);

    expect(lines.changeQty(keyboard.id, -1).single.qty, 1);
    expect(lines.changeQty(keyboard.id, -1).changeQty(keyboard.id, -1), isEmpty);
  });

  test('totals are derived from lines and coupon', () {
    final state = const CartState()
        .addProduct(keyboard)
        .addProduct(keyboard)
        .addProduct(mouse)
        .applyCoupon('save10');

    expect(state.itemCount, 3);
    expect(state.subtotal, 123);
    expect(state.discount, closeTo(12.3, 0.001));
    expect(state.total, closeTo(110.7, 0.001));
  });

  test('invalid coupon keeps the previous coupon and stores an error', () {
    final state = const CartState().applyCoupon('SAVE10').applyCoupon('NOPE');

    expect(state.coupon, 'SAVE10');
    expect(state.couponError, 'Invalid coupon code');
  });

  test('states with equal content are equal', () {
    final a = const CartState().addProduct(keyboard).applyCoupon('SAVE10');
    final b = const CartState().addProduct(keyboard).applyCoupon('SAVE10');

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a.applyCoupon('SAVE10'), a);
  });

  test('recordedFrom and undone round-trip the history', () {
    const initial = CartState();
    final added = initial.addProduct(keyboard).recordedFrom(initial);

    expect(added.canUndo, isTrue);
    expect(added.undone().lines, isEmpty);
    expect(added.undone().canUndo, isFalse);
    expect(added.recordedFrom(added), added);
  });
}
