import 'package:flutter/material.dart';  
import 'package:flutter_riverpod/flutter_riverpod.dart';  
import 'package:go_router/go_router.dart';  
  
import '../../../shared/widgets/responsive_shell.dart';  
  
class LandingScreen extends ConsumerWidget {  
  const LandingScreen({super.key});  
  
  @override  
  Widget build(BuildContext context, WidgetRef ref) {  
    final theme = Theme.of(context);  
    return ResponsiveShell(  
      title: 'School Recommendation System',  
      showNav: false,  
      child: Column(  
        crossAxisAlignment: CrossAxisAlignment.stretch,  
        children: [  
          const SizedBox(height: 48),  
          Icon(  
            Icons.school_outlined,  
            size: 80,  
            color: theme.colorScheme.primary,  
          ),  
          const SizedBox(height: 24),  
          Text(  
            'Find the perfect school for your child',  
            textAlign: TextAlign.center,  
            style: theme.textTheme.headlineMedium,  
          ),  
          const SizedBox(height: 16),  
          Text(  
            'Compare schools, read reviews, and make informed decisions '  
            'about your child\'s education in Ethiopia.',  
            textAlign: TextAlign.center,  
            style: theme.textTheme.bodyLarge?.copyWith(  
              color: theme.colorScheme.onSurfaceVariant,  
            ),  
          ),  
          const SizedBox(height: 48),  
          Card(  
            child: Padding(  
              padding: const EdgeInsets.all(24),  
              child: Column(  
                children: [  
                  Icon(Icons.search_outlined, size: 48, color: theme.colorScheme.primary),  
                  const SizedBox(height: 12),  
                  Text('Browse Schools', style: theme.textTheme.titleLarge),  
                  const SizedBox(height: 8),  
                  Text(  
                    'Explore schools by curriculum, location, and facilities.',  
                    textAlign: TextAlign.center,  
                  ),  
                ],  
              ),  
            ),  
          ),  
          const SizedBox(height: 16),  
          Card(  
            child: Padding(  
              padding: const EdgeInsets.all(24),  
              child: Column(  
                children: [  
                  Icon(Icons.compare_arrows_outlined, size: 48, color: theme.colorScheme.primary),  
                  const SizedBox(height: 12),  
                  Text('Compare Options', style: theme.textTheme.titleLarge),  
                  const SizedBox(height: 8),  
                  Text(  
                    'Side-by-side comparison of tuition, facilities, and more.',  
                    textAlign: TextAlign.center,  
                  ),  
                ],  
              ),  
            ),  
          ),  
          const SizedBox(height: 32),  
          FilledButton(  
            onPressed: () => context.go('/register'),  
            style: FilledButton.styleFrom(  
              padding: const EdgeInsets.symmetric(vertical: 16),  
            ),  
            child: const Text('Start Here', style: TextStyle(fontSize: 18)),  
          ),  
          const SizedBox(height: 16),  
          TextButton(  
            onPressed: () => context.go('/login'),  
            child: const Text('Already have an account? Sign in'),  
          ),  
        ],  
      ),  
    );  
  }  
}