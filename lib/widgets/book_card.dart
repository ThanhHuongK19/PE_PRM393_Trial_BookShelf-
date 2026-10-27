import 'package:flutter/material.dart';

import '../models/book.dart';

class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    required this.onFavoriteChanged,
    this.favoriteOverride,
    this.isFavoriteUpdating = false,
  });

  final Book book;
  final VoidCallback onTap;
  final ValueChanged<bool> onFavoriteChanged;
  final bool? favoriteOverride;
  final bool isFavoriteUpdating;

  @override
  Widget build(BuildContext context) {
    final isFavorite = favoriteOverride ?? book.favorite;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        title: Text(
          book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(
                '${book.genre} · ${book.status}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        trailing: IconButton(
          tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          onPressed: isFavoriteUpdating
              ? null
              : () => onFavoriteChanged(!isFavorite),
          icon: Icon(
            isFavorite ? Icons.star : Icons.star_border,
            color: isFavorite ? Colors.amber : null,
          ),
        ),
      ),
    );
  }
}
