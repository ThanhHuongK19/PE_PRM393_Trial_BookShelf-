import 'book.dart';

/// Applies the book-list controls and keeps results in their display order.
class BookListFilter {
  const BookListFilter({
    this.query = '',
    this.genre,
    this.status,
    this.favoritesOnly = false,
  });

  final String query;
  final String? genre;
  final String? status;
  final bool favoritesOnly;

  List<Book> apply(Iterable<Book> books) {
    final normalizedQuery = query.trim().toLowerCase();
    final result = books.where((book) {
      final matchesQuery = normalizedQuery.isEmpty ||
          book.title.toLowerCase().contains(normalizedQuery) ||
          book.author.toLowerCase().contains(normalizedQuery);
      return matchesQuery &&
          (genre == null || book.genre == genre) &&
          (status == null || book.status == status) &&
          (!favoritesOnly || book.favorite);
    }).toList();

    result.sort((a, b) {
      final titleOrder =
          a.title.trim().toLowerCase().compareTo(b.title.trim().toLowerCase());
      if (titleOrder != 0) return titleOrder;
      final authorOrder = a.author
          .trim()
          .toLowerCase()
          .compareTo(b.author.trim().toLowerCase());
      if (authorOrder != 0) return authorOrder;
      return a.id.compareTo(b.id);
    });
    return result;
  }
}

class BookStatusCount {
  const BookStatusCount(this.status, this.count);

  final String status;
  final int count;
}

class BookListSummary {
  const BookListSummary({
    required this.bookCount,
    required this.favoriteCount,
    required this.statusCounts,
  });

  final int bookCount;
  final int favoriteCount;
  final List<BookStatusCount> statusCounts;

  factory BookListSummary.fromBooks(Iterable<Book> books) {
    var bookCount = 0;
    var favoriteCount = 0;
    final counts = <String, int>{};
    for (final book in books) {
      bookCount++;
      if (book.favorite) favoriteCount++;
      counts.update(book.status, (count) => count + 1, ifAbsent: () => 1);
    }

    final statusCounts = counts.entries
        .map((entry) => BookStatusCount(entry.key, entry.value))
        .toList()
      ..sort((a, b) {
        final countOrder = b.count.compareTo(a.count);
        if (countOrder != 0) return countOrder;
        return Book.statuses.indexOf(a.status).compareTo(
          Book.statuses.indexOf(b.status),
        );
      });

    return BookListSummary(
      bookCount: bookCount,
      favoriteCount: favoriteCount,
      statusCounts: statusCounts,
    );
  }
}
