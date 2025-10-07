import 'package:flutter/material.dart';

// Helper for top-of-screen error banners
MaterialBanner appErrorBanner(BuildContext context, {required String message, VoidCallback? onRetry}) {
  return MaterialBanner(
    content: Text(message),
    leading: const Icon(Icons.error_outline, color: Colors.redAccent),
    actions: [
      if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Retry')),
      TextButton(onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(), child: const Text('Dismiss')),
    ],
    backgroundColor: Theme.of(context).colorScheme.errorContainer,
  );
}

// Optional widget form for embedding banners inline (not used by ScaffoldMessenger)
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorBanner({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) => appErrorBanner(context, message: message, onRetry: onRetry);
}
