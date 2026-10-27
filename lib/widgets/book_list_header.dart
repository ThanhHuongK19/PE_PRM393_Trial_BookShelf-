import 'package:flutter/material.dart';

class BookListHeader extends StatelessWidget {
  const BookListHeader({
    super.key,
    required this.email,
    required this.onLogout,
    this.isLoggingOut = false,
  });

  final String email;
  final VoidCallback onLogout;
  final bool isLoggingOut;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.person_outline)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton.icon(
            onPressed: isLoggingOut ? null : onLogout,
            icon: isLoggingOut
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
