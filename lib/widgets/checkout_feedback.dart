import 'package:flutter/material.dart';

void showOrderConfirmation(BuildContext context, String orderId) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentMaterialBanner()
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('Order $orderId placed')));
}

void showCheckoutFailure(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentMaterialBanner()
    ..showMaterialBanner(
      MaterialBanner(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        actions: [
          TextButton(
            onPressed: () => messenger.hideCurrentMaterialBanner(),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
}

void hideCheckoutFailure(BuildContext context) =>
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
