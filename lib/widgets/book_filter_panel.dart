import 'package:flutter/material.dart';

import '../models/book.dart';

class BookFilterPanel extends StatelessWidget {
  const BookFilterPanel({
    super.key,
    required this.searchController,
    required this.genre,
    required this.status,
    required this.favoritesOnly,
    required this.onSearchChanged,
    required this.onGenreChanged,
    required this.onStatusChanged,
    required this.onFavoritesChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final String? genre;
  final String? status;
  final bool favoritesOnly;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onGenreChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<bool> onFavoritesChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Column(
      children: [
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: const InputDecoration(
            labelText: 'Search title or author',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FilterDropdown(
                label: 'Genre',
                allLabel: 'All',
                value: genre,
                options: Book.genres,
                onChanged: onGenreChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FilterDropdown(
                label: 'Status',
                allLabel: 'All',
                value: status,
                options: Book.statuses,
                onChanged: onStatusChanged,
              ),
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Favorites only'),
          value: favoritesOnly,
          onChanged: onFavoritesChanged,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear'),
          ),
        ),
      ],
    ),
  );
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.allLabel,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String allLabel;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String?>(
        value: value,
        isExpanded: true,
        hint: Text(allLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(allLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          ...options.map(
            (option) => DropdownMenuItem<String?>(
              value: option,
              child: Text(option, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    ),
  );
}
