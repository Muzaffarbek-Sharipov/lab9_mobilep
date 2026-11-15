# Lab 9: One Cart, Four Ways: Notes

Student / partner: ______________________ / ______________________

All code is comment-free by design. Cart logic lives once in `lib/models/cart.dart`; every state holder only calls it.

## Design decisions shared by all four parts

| Decision | Where | Why |
| --- | --- | --- |
| `Product`, `CartLine`, `CartState`, `CartSummary` are immutable and have value equality (`==`, `hashCode`, lists compared with `listEquals`) | `models/cart.dart` | Required for Riverpod, Cubit and Bloc to skip duplicate state; `setState` ignores it but benefits from the same code |
| Every transformation is a pure method on `CartState` (`addProduct`, `changeQty`, `applyCoupon`, `submitting`, `succeeded`, `failed`, `restoring`, `recordedFrom`, `undone`) | `models/cart.dart` | No pricing or coupon rule is duplicated in any notifier, cubit or bloc |
| `total`, `discount`, `subtotal`, `itemCount`, `summary`, `canUndo` are getters | `models/cart.dart` | Derived values are never stored (see T3) |
| Coupon codes are trimmed and case-insensitive; an invalid code keeps the previously applied coupon and sets `couponError` | `CartState.applyCoupon` | Predictable behaviour; error is part of state |
| Undo records a snapshot only when the new state differs from the old one; checkout status changes are never recorded; a successful checkout clears the history | `recordedFrom`, `succeeded` | A duplicate coupon must not create a no-op undo step; undoing past a paid order would resurrect paid items |
| Undo restores lines and coupon but keeps the current checkout fields (`restoring`) | `CartState.restoring` | Undo must not replay an old `success` and re-trigger the SnackBar |
| While `status == submitting` the UI disables chips, steppers, swipe-to-remove, coupon and undo | `CartBody`, each page | The total sent to the API must match the cart that will be cleared |
| Removing a line is done by swiping it away; the stepper handles quantity | `CartBody` | T1 replaces the delete icon with `−` / `+`; `remove` stays in every state holder and is still reachable and undoable |
| `CheckoutApi` has a `const` constructor and is injected (constructor or provider) | all styles | Tests substitute a mock |

## Part 1: answers

**Why is `CartLine` immutable with a `copyWith` instead of a mutable `qty` field? Which of the four styles would still "work" with mutation, and why is that a trap?**
Immutability makes "new value" mean "new object", so change detection can be done with `==` or identity. Only `setState` would still appear to work with mutation, because it marks the element dirty unconditionally and rebuilds regardless of whether the data changed. In Riverpod, Cubit and Bloc a mutated list is the same object as the old state, so `emit` / `state =` see "no change" and drop the update. It is a trap for three reasons: the app seems fine until the code is moved to another style, undo snapshots would alias the live object and change retroactively, and `select` / `buildWhen` compare old with new, so a mutated object makes them always see "equal".

**Why does `CartBody` take callbacks rather than importing a provider or a bloc directly?**
It keeps the widget a pure function of its inputs: one widget serves all four styles, it can be previewed and widget-tested with plain data, and the choice of state management stays in exactly one place per page. Importing a provider or bloc would couple it to one style and make the four-way comparison meaningless. It also takes the summary card as a `Widget`, so each style plugs in its own selective subscription.

## Part 2: setState

Subtask map: T1 `changeQty` in `CartLines` (model) + `_changeQty`; T2 `CartState` + `_applyCoupon`; T3 `CartState.summary` getters; T4 `_checkout`; T5 `_history` + `_undo`; T6 `test/setstate_cart_test.dart`.

**T3: why would storing `total` be a bug waiting to happen?**
A stored total duplicates information already contained in `lines` and `coupon`. Every mutation path (add, remove, quantity, coupon, undo, checkout) would have to remember to recompute it, and one forgotten path leaves a stale price on screen or in the API call. It would also leak into `==` and into undo snapshots, so a restored snapshot could carry a total that disagrees with its lines. A getter has one source of truth and cannot drift.

**T4: what happens without `if (!mounted) return;` after the `await`?**
The checkout takes 1.5 s. If the user pops the page meanwhile, the `State` is disposed. The continuation still runs and calls `setState`, which throws `setState() called after dispose()` in debug and signals a leak. The follow-up `ScaffoldMessenger.of(context)` also fails with "Looking up a deactivated widget's ancestor is unsafe". The guard turns the late result into a no-op.

**T6: note on the test.**
Of the nine statements in `setstate_cart_test.dart`, eight are about finding widgets and driving gestures (`pumpWidget`, `find.text`, `tap`, `enterText`, `pump`) and only one is a cart assertion. It breaks if a label or layout changes even though the cart logic is untouched. The Riverpod and Bloc tests assert logic directly.

**After T4, how would a second page (an order history) read the cart? What would you have to change?**
It cannot: `_state` is a private field of one `State` object. The state and its methods would have to be lifted into a common ancestor above both pages (above the `Navigator`, i.e. above `MaterialApp`) and passed down by constructor arguments or an `InheritedWidget` / `ChangeNotifier`. That is the prop-drilling the other three styles remove.

**After T5, where does `_history` live, and what happens on hot restart vs hot reload?**
`_history` is a field of `_SetStateCartPageState`, next to `_state`. Hot reload keeps the `State` object and re-runs `build`, so the cart and the history survive. Hot restart re-runs `main`, destroys every `State`, and both are lost. Popping the page also destroys them.

## Part 3: Riverpod

Subtask map: T1 `changeQty`; T2 `Notifier<CartState>` + `applyCoupon`; T3 `_RiverpodSummary` with `select`; T4 `checkoutApiProvider`, `checkout()`, `ref.listen`; T5 `_history` + `undo()` + `canUndoProvider`; T6 `test/riverpod_cart_test.dart`.

**T2: does `state = state.copyWith(coupon: code)` notify when the code is unchanged?**
Before value equality exists, yes. `copyWith` builds a new `CartState`, the default `==` is identity, so old != new and every listener is told about a non-change. With `==` / `hashCode` overridden (already done in the model) the new state equals the old one and Riverpod does not notify. To observe it, add temporarily `ref.listen(cartProvider, (p, n) => debugPrint('cart changed'))` in the page and apply `SAVE10` twice. Because the notifier's `_commit` also compares `next == state` before touching history, remove that line and the `==` override together to see the "before" behaviour.

**T3: how to verify the selective rebuild.**
`_RiverpodSummary` prints `RiverpodSummary rebuilt: ...` in its `build`. Applying an invalid coupon changes `couponError` only, so the selected `CartSummary` is equal and nothing is printed. Pressing `+` changes the summary and prints one line. It selects the whole `CartSummary` value (item count, subtotal, discount, total) instead of only `total` so the card can never show a stale figure; `total` is part of that value, so the rebuild rule is the same.

**T4: why is no `mounted` check needed?**
The state lives in the `ProviderContainer`, not in a widget, and the notifier only assigns `state`; it never touches a `BuildContext`. The widget side effects are in `ref.listen`, which Riverpod unsubscribes automatically when the widget is disposed. With the non-autoDispose `cartProvider` the notifier outlives the page. If the provider were `autoDispose` and disposed mid-flight, the equivalent guard would be `ref.mounted`.

**T5: what must `canUndoProvider` watch, and what happened with `autoDispose`?**
It must `ref.watch(cartProvider)` (the state), because `_history` is a plain field and the notifier instance never changes, so reading only the notifier would never recompute. `_commit` fills `_history` before assigning `state`, so every recomputation sees the new history. With `cartProvider` made `autoDispose`, popping the page removes the last listener, the provider and its notifier are disposed, and returning rebuilds from `build()`: an empty cart and an empty history. The history was a field of the disposed notifier. The delivered code keeps the non-autoDispose provider.

**Name the places you used `ref.read` and `ref.watch`, and justify each.**

| Call | Location | Justification |
| --- | --- | --- |
| `ref.watch(cartProvider)` | `RiverpodCartPage.build` | The page displays lines, coupon and status; it must rebuild on change |
| `ref.watch(canUndoProvider)` | `RiverpodCartPage.build` | The Undo button must update when history appears or disappears |
| `ref.watch(cartProvider.select((s) => s.summary))` | `_RiverpodSummary.build` | Rebuild only when the displayed summary changes |
| `ref.watch(cartProvider)` | `canUndoProvider` | Recompute whenever state (and therefore history) changes |
| `ref.read(cartProvider.notifier)` | `RiverpodCartPage.build` | Method handles for callbacks, no subscription needed |
| `ref.read(cartProvider)` ×2 | `ref.listen` callback | One-off read of `orderId` / `checkoutError` at the moment of the event |
| `ref.read(checkoutApiProvider)` | `CartNotifier.checkout` | A dependency lookup inside a method; watching would be wrong |
| `ref.read(cartProvider.notifier)` | `canUndoProvider` | The notifier is only needed to read `canUndo`; the watch above provides the trigger |

Five `ref.read` call sites and four `ref.watch` call sites in total. No `ref.watch` appears in a callback and no `ref.read` is used to display data.

**Why does the summary card rebuild less often than the setState version?**
In the setState page the whole `State` rebuilds on every change and re-creates the card. Here the card is a `const` widget with its own `select` subscription, so a parent rebuild cannot rebuild it (identical const instance), and it only rebuilds when the selected `CartSummary` value changes.

## Part 4: Cubit

Subtask map: T1 `changeQty`; T2 `Cubit<CartState>` with value equality; T3 `BlocSelector` summary; T4 constructor-injected `CheckoutApi`, `BlocListener` with `listenWhen`, `isClosed`; T5 history folded into `CartState`; T6 `test/cubit_cart_test.dart`.

**T2: the dropped emit.**
Apply `SAVE10` twice. `applyCoupon` calls `emit` both times; the second state equals the current one, so the cubit skips it and `AppBlocObserver.onChange` prints a single `[change]` line for the two taps. (A cubit that has never emitted still emits its first state even if equal, so the effect shows on the second tap.)

**T4: what does `emit` do after `close()`?**
It throws `StateError: Cannot emit new states after calling close`. `checkout()` guards both resume points with `if (isClosed) return;`.

**T5: why a getter on the cubit is not enough.**
`BlocBuilder` / `BlocSelector` react only to emitted states. A `canUndo` getter on the cubit changes without any emission, so the button would not rebuild. The fix is to make history part of `CartState` (`CartState.history`, `CartState.canUndo`), so the button is driven by the stream like everything else.

**T6: sequence vs end state.**
The blocTest asserts the exact sequence of emissions (three states, then `submitting` followed by `failure`). The Riverpod test asserts only the final state.

**What would break if `BlocProvider` were inside `CartBody`?**
The `AppBar` undo button, the `BlocListener` and the page-level `BlocBuilder` are all above it, so `context.read<CartCubit>()` would throw `ProviderNotFoundException`. `CartBody` would also stop being dumb, and the cubit's lifetime would depend on that widget's position in the tree (state lost and `close()` called if it is ever rebuilt under a different parent).

**Riverpod equivalents.**

| Bloc | Riverpod |
| --- | --- |
| `BlocProvider` | `NotifierProvider` declaration plus `ProviderScope` (nested `ProviderScope` overrides for a narrower scope) |
| `BlocBuilder` | `ref.watch` in a `ConsumerWidget` / `Consumer` |
| `BlocListener` | `ref.listen` |
| `context.read` | `ref.read` |
| `buildWhen` / `BlocSelector` | `ref.watch(provider.select(...))` |

## Part 5: Bloc

Subtask map: T1 `CartQtyChanged`; T2 `CartCouponApplied` + `AppBlocObserver.onTransition`; T3 `_BlocSummary`; T4 `CartCheckoutRequested` with `droppable()` and `emit.isDone`; T5 `CartUndone` + `CartEventHistory.isUndoable`; T6 `test/bloc_cart_test.dart`.

**T2: what extra information does the transition log give?**
`onTransition` prints the event (`CartProductAdded`, `CartCouponApplied`, ...) between the current and the next state. A cubit's `onChange` shows only before and after, with no cause.

**T4: triple tap.**
With `transformer: droppable()` the second and third `CartCheckoutRequested` are discarded while the first handler is awaiting the API, so `submit` is called once and one `submitting` state is emitted (proved by the third blocTest and `verify(...).called(1)`). The handler deliberately has no `isSubmitting` guard, so `droppable()` is the only mechanism under test. A cubit has no transformers: without a guard, three taps would start three concurrent `submit` calls and three orders. `CartCubit.checkout` uses the imperative guard `state.isSubmitting`.

**T5: which events are undoable?**
Defined by an exhaustive `switch` on the sealed `CartEvent` in `cart_event.dart`: `CartProductAdded`, `CartProductRemoved`, `CartQtyChanged` and `CartCouponApplied` are undoable. `CartUndone` (undo of undo would loop) and `CartCheckoutRequested` (status change, not a cart edit) are not. Adding a new event makes the compiler force that decision.

**When is the event layer worth its boilerplate?**
Clearly better than a Cubit: checkout. It needs concurrency control (`droppable`, or `restartable` for a search-style flow) and a named trace of what the user asked for. Pure overhead: the quantity stepper or the coupon. They are synchronous pure transformations, and each needs an event class, a handler and a dispatch call for no benefit over `cubit.changeQty(id, 1)`.

**Which of the four styles can drop duplicate taps declaratively, and how do the others do it?**
Only Bloc, with `transformer: droppable()`. In the other three the same result is imperative: a guard clause on status (`if (state.isSubmitting) return;`, used in the Riverpod notifier, the cubit and the setState page), plus disabling the button while submitting, which `CartBody` does.

## Checkpoint questions

**1. For each style, where does the state live and when does it die?**
- setState: a field of the `State` object; dies when the widget leaves the tree (page popped) or on hot restart.
- Riverpod: inside the `ProviderContainer` of the root `ProviderScope`; dies with the scope, on `invalidate`, or (if `autoDispose`) when the last listener goes.
- Cubit: in the `CartCubit` owned by the `BlocProvider`; dies when the provider is disposed, which calls `close()`.
- Bloc: same as Cubit, in the `CartBloc` owned by the `BlocProvider`.

**2. What is the single public mutation API in each style? Which has none?**
Riverpod `Notifier`: its public methods, which assign `state` (only the notifier can). Cubit: its public methods, which call `emit`. Bloc: `add(event)` only. `setState` has none: the state is a private field changed through a private method, and no other widget can mutate it.

**3. Mapping and the place of `setState`.**
`ref.watch` is `BlocBuilder` / `context.watch` (subscribe and rebuild); `ref.read` is `context.read` (one-off lookup); `ref.listen` is `BlocListener` (side effects, no build). `setState` has no subscription layer at all: the owner is holder and subscriber at once, and `setState` fuses "assign the new value" with "mark dirty", which Riverpod and Bloc separate into `state =` / `emit` and the subscription.

**4. Why do Riverpod, Cubit and Bloc skip notification when `new == old`, and what two things must you do to `CartState`?**
It avoids pointless rebuilds and downstream work when nothing changed. `CartState` must (a) override `==` and `hashCode` with value semantics, comparing `lines` and `history` by content with `listEquals`, and have `CartLine` and `Product` do the same; and (b) be treated as immutable, with every change producing a new instance through `copyWith` and never mutating the old list in place.

**5. Which guard after the `await` in `checkout`, and why do they differ?**

| Style | Guard | Why |
| --- | --- | --- |
| setState | `if (!mounted) return;` | The state object can outlive its element; `setState` after dispose throws |
| Riverpod | none | State is held by the container, not the widget; widget effects are in `ref.listen`, which unsubscribes itself (`ref.mounted` only if `autoDispose`) |
| Cubit | `if (isClosed) return;` | `emit` after `close()` throws, and the provider closes the cubit when the page is popped |
| Bloc | `if (emit.isDone) return;` | The emitter is scoped to the handler and is cancelled when the bloc closes |

The guards differ because the owner of the state differs: a widget, a container, a stream with an explicit `close()`, or an event handler.

## Comparison table

Lines are non-blank Dart lines (no comments exist in the code). "LOC T1–T5" counts the state holder plus its page file(s) for that style (shared model, services and widgets are excluded). Tests count the style's test file.

| | setState | Riverpod | Cubit | Bloc |
| --- | --- | --- | --- | --- |
| LOC T1–T5 | 76 | 106 | 113 | 172 |
| Lines of test code | 16 | 36 | 48 | 76 |
| Files (production + test) | 2 | 3 | 3 | 4 |
| Strength | Fewest concepts, one file, nothing to install | State outside the tree, selective rebuilds with `select`, tests need no widgets or `BuildContext` | Explicit, small API; scoped to a subtree; sequence-asserting `blocTest` | Every change is a named event: transition log, per-event transformers such as `droppable()`, exhaustive handling of sealed events |
| Weakness | State is private and dies with the page; whole page rebuilds; widget-bound tests; `mounted` bookkeeping | Not tied to widget lifetime, so `autoDispose` and history behaviour must be reasoned about; reads vs watches is easy to get wrong | Getters are invisible to the UI (history had to move into state); `isClosed` guards | Most boilerplate (about 1.5× the Cubit); an event class and a handler for trivial synchronous changes |

Shared code (model, service, widgets, observer, `main.dart`): 546 lines; model test: 49 lines (6 tests).

## Rubric evidence map

| Item | Evidence |
| --- | --- |
| Part 1 (5) | tag `p1-shared`; `lib/models`, `lib/services`, `lib/widgets`, `lib/main.dart`; two questions answered above |
| Part 2 (10) | tag `p2-setstate`; `lib/setstate/cart_page_setstate.dart`; `test/setstate_cart_test.dart` |
| Part 3 (15) | tag `p3-riverpod`; `lib/riverpod/*`; selective rebuild via `_RiverpodSummary` debugPrint; 2 tests |
| Part 4 (15) | tag `p4-cubit`; `lib/cubit/*`; dropped emit visible through `AppBlocObserver`; 2 tests |
| Part 5 (15) | tag `p5-bloc`; `lib/bloc/*`; transition log and `droppable()`; 3 tests |
| NOTES.md (5) | five checkpoint questions above |
| Comparison table (10) | table above |
| Screen recording (5) | to be recorded: follow the script in README.md |
| Stretch goals | not implemented; the score is capped at 60 points, which the main items already exceed |

## Submission checklist

- [x] Tags `p1-shared` … `p5-bloc` in the repository
- [x] 8 required tests written (1 setState, 2 Riverpod, 2 Cubit, 3 Bloc) plus 6 model tests
- [x] NOTES.md answers the five checkpoint questions, all inline questions and the comparison table
- [ ] `flutter analyze` clean: run on your machine (not executed in the authoring environment)
- [ ] `flutter test` green: run on your machine (not executed in the authoring environment)
- [ ] Screen recording under 45 s in two of the four pages
