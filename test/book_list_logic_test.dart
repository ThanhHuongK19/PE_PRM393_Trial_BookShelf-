import 'package:bookshelf/models/book.dart';
import 'package:bookshelf/models/book_list_logic.dart';
import 'package:flutter_test/flutter_test.dart';

Book _book({
  required String id,
  required String title,
  required String author,
  String genre = 'Fiction',
  String status = 'To Read',
  bool favorite = false,
}) => Book(
  id: id,
  userId: 'user-1',
  title: title,
  author: author,
  genre: genre,
  status: status,
  rating: null,
  favorite: favorite,
  notes: '',
  createdAt: DateTime(2026),
);

void main() {
  final books = [
    _book(
      id: '1',
      title: 'Dune',
      author: 'Frank Herbert',
      genre: 'Fiction',
      status: 'Finished',
      favorite: true,
    ),
    _book(
      id: '2',
      title: 'dune Messiah',
      author: 'Frank Herbert',
      genre: 'Fiction',
      status: 'Reading',
    ),
    _book(
      id: '3',
      title: 'Algorithms',
      author: 'Robert Sedgewick',
      genre: 'Academic',
      status: 'To Read',
      favorite: true,
    ),
    _book(
      id: '4',
      title: 'Dune',
      author: 'Another Author',
      genre: 'Other',
      status: 'To Read',
    ),
  ];

  test('search trims ends and matches title or author without case', () {
    final results = const BookListFilter(query: '  FRANK HERBERT  ')
        .apply(books);
    expect(results.map((book) => book.id), ['1', '2']);
  });

  test('genre, status, search, and favorites filters combine with AND', () {
    final results = const BookListFilter(
      query: 'dune',
      genre: 'Fiction',
      status: 'Finished',
      favoritesOnly: true,
    ).apply(books);
    expect(results.map((book) => book.id), ['1']);
  });

  test('sorting is by title then author, both case-insensitive', () {
    final results = const BookListFilter().apply(books);
    expect(results.map((book) => book.id), ['3', '4', '1', '2']);
  });

  test('summary counts filtered books and sorts status ties by exam order', () {
    final results = const BookListFilter(genre: 'Fiction').apply(books);
    final summary = BookListSummary.fromBooks(results);
    expect(summary.bookCount, 2);
    expect(summary.favoriteCount, 1);
    expect(summary.statusCounts.map((item) => '${item.status}:${item.count}'), [
      'Reading:1',
      'Finished:1',
    ]);
  });
}
