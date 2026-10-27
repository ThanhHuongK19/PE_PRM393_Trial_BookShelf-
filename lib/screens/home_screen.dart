import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('BookShelf'),
      actions: [
        TextButton(
          onPressed: () => context.go('/sign-in'),
          child: const Text('Login'),
        ),
        TextButton(
          onPressed: () => context.go('/sign-up'),
          child: const Text('Register'),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'BookShelf',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Keep your reading list organized, track your progress, '
                  'and save the books you love.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                const _FeatureCard(
                  icon: Icons.library_books_outlined,
                  title: 'Track your books',
                  description:
                      'Keep the books you own or want to read together.',
                ),
                const _FeatureCard(
                  icon: Icons.sort,
                  title: 'Sort by status',
                  description: 'See what is next, in progress, or finished.',
                ),
                const _FeatureCard(
                  icon: Icons.favorite_border,
                  title: 'Rate your favorites',
                  description: 'Mark favorite books and add a personal rating.',
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.go('/sign-in'),
                  child: const Text('Login'),
                ),
                OutlinedButton(
                  onPressed: () => context.go('/sign-up'),
                  child: const Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(description),
    ),
  );
}
