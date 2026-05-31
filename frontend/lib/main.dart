import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/router.dart';
import 'core/theme.dart';

void main() {
  usePathUrlStrategy();
  runApp(const ProviderScope(child: SchoolRecApp()));
}

class SchoolRecApp extends ConsumerWidget {
  const SchoolRecApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Fidel Guide',
      theme: appTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
