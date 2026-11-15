# cart_four_ways

One shopping cart implemented four times (setState, Riverpod, Cubit, Bloc) on top of a shared, style-independent model.

## First run

The archive contains the Dart sources only. Generate the platform folders once, then fetch packages:

```
flutter create . --project-name cart_four_ways --platforms=android,ios
flutter pub get
flutter analyze
flutter test
flutter run
```

## Layout

```
lib/
  main.dart
  models/cart.dart
  services/checkout_api.dart
  widgets/cart_body.dart  cart_summary.dart  coupon_field.dart  checkout_feedback.dart
  observers/app_bloc_observer.dart
  setstate/cart_page_setstate.dart
  riverpod/cart_notifier.dart  cart_page_riverpod.dart
  cubit/cart_cubit.dart  cart_page_cubit.dart
  bloc/cart_event.dart  cart_bloc.dart  cart_page_bloc.dart
test/
  cart_model_test.dart  setstate_cart_test.dart  riverpod_cart_test.dart
  cubit_cart_test.dart  bloc_cart_test.dart
NOTES.md
```

## Screen recording script (under 45 s, two pages, for example setState and Bloc)

1. Add Keyboard twice and Mouse once.
2. Use `+` and `−` on Keyboard, then swipe Mouse away.
3. Apply `NOPE` (red error), then `SAVE10` (total changes).
4. Add Monitor three times so the subtotal exceeds 500 and press Checkout: spinner, then the "Card declined" banner and the cart stays.
5. Press Undo twice.
6. Repeat on the second page. On the Bloc page press Checkout three times quickly and show that one order is submitted.

## Checks to demonstrate to the instructor

- Riverpod and Cubit/Bloc summary card: the debug console prints `... Summary rebuilt` only when the summary changes (invalid coupon prints nothing).
- Cubit: apply `SAVE10` twice; `[change]` is printed once.
- Bloc: `[transition]` lines show the event name.
