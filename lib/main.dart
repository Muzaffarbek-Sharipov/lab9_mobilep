import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bloc/cart_page_bloc.dart';
import 'cubit/cart_page_cubit.dart';
import 'observers/app_bloc_observer.dart';
import 'riverpod/cart_page_riverpod.dart';
import 'setstate/cart_page_setstate.dart';

void main() {
  Bloc.observer = const AppBlocObserver();
  runApp(const ProviderScope(child: CartApp()));
}

class CartApp extends StatelessWidget {
  const CartApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'One Cart, Four Ways',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const HomePage(),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('One Cart, Four Ways')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: () => _open(context, const SetStateCartPage()),
                  child: const Text('setState'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => _open(context, const RiverpodCartPage()),
                  child: const Text('Riverpod'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => _open(context, const CubitCartPage()),
                  child: const Text('Cubit'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => _open(context, const BlocCartPage()),
                  child: const Text('Bloc'),
                ),
              ],
            ),
          ),
        ),
      );
}
