import 'package:flutter/foundation.dart';

class Product {
  const Product({required this.id, required this.name, required this.price});

  final String id;
  final String name;
  final double price;

  @override
  bool operator ==(Object other) =>
      other is Product &&
      other.id == id &&
      other.name == name &&
      other.price == price;

  @override
  int get hashCode => Object.hash(id, name, price);
}

const catalog = [
  Product(id: 'p1', name: 'Keyboard', price: 49),
  Product(id: 'p2', name: 'Mouse', price: 25),
  Product(id: 'p3', name: 'Monitor', price: 199),
];

const coupons = <String, double>{'SAVE10': 0.10};

class CartLine {
  const CartLine({required this.product, required this.qty});

  final Product product;
  final int qty;

  double get subtotal => product.price * qty;

  CartLine copyWith({int? qty}) =>
      CartLine(product: product, qty: qty ?? this.qty);

  @override
  bool operator ==(Object other) =>
      other is CartLine && other.product == product && other.qty == qty;

  @override
  int get hashCode => Object.hash(product, qty);
}

extension CartLines on List<CartLine> {
  List<CartLine> withProduct(Product p) {
    final i = indexWhere((l) => l.product.id == p.id);
    if (i == -1) return [...this, CartLine(product: p, qty: 1)];
    return [
      for (final l in this)
        l.product.id == p.id ? l.copyWith(qty: l.qty + 1) : l,
    ];
  }

  List<CartLine> without(String productId) =>
      [for (final l in this) if (l.product.id != productId) l];

  List<CartLine> changeQty(String productId, int delta) => [
        for (final l in this)
          if (l.product.id != productId)
            l
          else if (l.qty + delta > 0)
            l.copyWith(qty: l.qty + delta),
      ];

  double get subtotal => fold(0, (s, l) => s + l.subtotal);

  int get itemCount => fold(0, (s, l) => s + l.qty);
}

enum CheckoutStatus { idle, submitting, success, failure }

class CartSummary {
  const CartSummary({
    required this.itemCount,
    required this.subtotal,
    required this.discount,
    required this.total,
  });

  final int itemCount;
  final double subtotal;
  final double discount;
  final double total;

  @override
  bool operator ==(Object other) =>
      other is CartSummary &&
      other.itemCount == itemCount &&
      other.subtotal == subtotal &&
      other.discount == discount &&
      other.total == total;

  @override
  int get hashCode => Object.hash(itemCount, subtotal, discount, total);
}

const Object _unset = Object();

class CartState {
  const CartState({
    this.lines = const <CartLine>[],
    this.coupon,
    this.couponError,
    this.status = CheckoutStatus.idle,
    this.orderId,
    this.checkoutError,
    this.history = const <CartState>[],
  });

  final List<CartLine> lines;
  final String? coupon;
  final String? couponError;
  final CheckoutStatus status;
  final String? orderId;
  final String? checkoutError;
  final List<CartState> history;

  int get itemCount => lines.itemCount;

  double get subtotal => lines.subtotal;

  double get discount {
    final rate = coupons[coupon];
    return rate == null ? 0 : subtotal * rate;
  }

  double get total => subtotal - discount;

  bool get isSubmitting => status == CheckoutStatus.submitting;

  bool get canUndo => history.isNotEmpty;

  CartSummary get summary => CartSummary(
        itemCount: itemCount,
        subtotal: subtotal,
        discount: discount,
        total: total,
      );

  CartState copyWith({
    List<CartLine>? lines,
    Object? coupon = _unset,
    Object? couponError = _unset,
    CheckoutStatus? status,
    Object? orderId = _unset,
    Object? checkoutError = _unset,
    List<CartState>? history,
  }) =>
      CartState(
        lines: lines ?? this.lines,
        coupon: identical(coupon, _unset) ? this.coupon : coupon as String?,
        couponError: identical(couponError, _unset)
            ? this.couponError
            : couponError as String?,
        status: status ?? this.status,
        orderId: identical(orderId, _unset) ? this.orderId : orderId as String?,
        checkoutError: identical(checkoutError, _unset)
            ? this.checkoutError
            : checkoutError as String?,
        history: history ?? this.history,
      );

  CartState addProduct(Product p) => copyWith(lines: lines.withProduct(p));

  CartState removeProduct(String productId) =>
      copyWith(lines: lines.without(productId));

  CartState changeQty(String productId, int delta) =>
      copyWith(lines: lines.changeQty(productId, delta));

  CartState applyCoupon(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      return copyWith(couponError: 'Enter a coupon code');
    }
    if (!coupons.containsKey(normalized)) {
      return copyWith(couponError: 'Invalid coupon code');
    }
    return copyWith(coupon: normalized, couponError: null);
  }

  CartState submitting() => copyWith(
        status: CheckoutStatus.submitting,
        orderId: null,
        checkoutError: null,
      );

  CartState succeeded(String orderId) =>
      CartState(status: CheckoutStatus.success, orderId: orderId);

  CartState failed(String message) =>
      copyWith(status: CheckoutStatus.failure, checkoutError: message);

  CartState snapshot() => copyWith(history: const <CartState>[]);

  CartState restoring(CartState previous) => previous.copyWith(
        status: status,
        orderId: orderId,
        checkoutError: checkoutError,
        history: history,
      );

  CartState recordedFrom(CartState previous) => this == previous
      ? this
      : copyWith(history: [...previous.history, previous.snapshot()]);

  CartState undone() => history.isEmpty
      ? this
      : restoring(history.last)
          .copyWith(history: history.sublist(0, history.length - 1));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CartState &&
          listEquals(other.lines, lines) &&
          other.coupon == coupon &&
          other.couponError == couponError &&
          other.status == status &&
          other.orderId == orderId &&
          other.checkoutError == checkoutError &&
          listEquals(other.history, history));

  @override
  int get hashCode => Object.hash(
        Object.hashAll(lines),
        coupon,
        couponError,
        status,
        orderId,
        checkoutError,
        Object.hashAll(history),
      );

  @override
  String toString() =>
      'CartState(items: $itemCount, coupon: $coupon, couponError: $couponError, '
      'status: ${status.name}, undo: ${history.length})';
}
