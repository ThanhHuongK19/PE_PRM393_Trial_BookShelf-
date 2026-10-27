import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../models/book_list_logic.dart';
import '../providers/auth_provider.dart';
import '../services/book_service.dart';
import '../widgets/auth_error_message.dart';
import '../widgets/book_card.dart';
import '../widgets/book_filter_panel.dart';
import '../widgets/book_list_header.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  String? _streamUserId;
  Stream<List<Book>>? _booksStream;
  final Set<String> _updatingFavoriteIds = {};
  final Map<String, bool> _optimisticFavorites = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedGenre;
  String? _selectedStatus;
  bool _favoritesOnly = false;
  bool _noticeCheckScheduled = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedGenre = null;
      _selectedStatus = null;
      _favoritesOnly = false;
    });
  }

  Future<void> _toggleFavorite(Book book, bool favorite) async {
    setState(() {
      _updatingFavoriteIds.add(book.id);
      _optimisticFavorites[book.id] = favorite;
    });
    try {
      await context.read<BookService>().setFavorite(
        book.id,
        favorite: favorite,
      );
    } catch (error) {
      if (mounted) {
        setState(() => _optimisticFavorites.remove(book.id));
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _updatingFavoriteIds.remove(book.id));
    }
  }

  Future<void> _logout() async {
    try {
      await context.read<AuthProvider>().signOut();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    _schedulePendingNoticeCheck();
    final user = authProvider.user;
    if (_streamUserId != user?.uid) {
      _streamUserId = user?.uid;
      _booksStream = user == null
          ? null
          : context.read<BookService>().watchBooks();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('BookShelf')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/books/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Book'),
      ),
      body: Column(
        children: [
          BookListHeader(
            email: user?.email ?? '',
            onLogout: _logout,
            isLoggingOut: authProvider.isBusy,
          ),
          Expanded(
            child: _booksStream == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<Book>>(
                    stream: _booksStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Could not load books: ${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final books = snapshot.data!.map((book) {
                        final optimisticFavorite =
                            _optimisticFavorites[book.id];
                        if (optimisticFavorite == null) return book;
                        if (optimisticFavorite == book.favorite) {
                          _optimisticFavorites.remove(book.id);
                          return book;
                        }
                        return book.copyWith(favorite: optimisticFavorite);
                      }).toList();
                      final filteredBooks = BookListFilter(
                        query: _searchQuery,
                        genre: _selectedGenre,
                        status: _selectedStatus,
                        favoritesOnly: _favoritesOnly,
                      ).apply(books);
                      final summary = BookListSummary.fromBooks(filteredBooks);

                      return CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                BookFilterPanel(
                                  searchController: _searchController,
                                  genre: _selectedGenre,
                                  status: _selectedStatus,
                                  favoritesOnly: _favoritesOnly,
                                  onSearchChanged: (value) =>
                                      setState(() => _searchQuery = value),
                                  onGenreChanged: (value) =>
                                      setState(() => _selectedGenre = value),
                                  onStatusChanged: (value) =>
                                      setState(() => _selectedStatus = value),
                                  onFavoritesChanged: (value) =>
                                      setState(() => _favoritesOnly = value),
                                  onClear: _clearFilters,
                                ),
                                _BookSummary(summary: summary),
                              ],
                            ),
                          ),
                          if (filteredBooks.isEmpty)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(child: Text('No books found')),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                              sliver: SliverList.separated(
                                itemCount: filteredBooks.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 4),
                                itemBuilder: (context, index) {
                                  final book = filteredBooks[index];
                                  return BookCard(
                                    book: book,
                                    favoriteOverride:
                                        _optimisticFavorites[book.id],
                                    isFavoriteUpdating: _updatingFavoriteIds
                                        .contains(book.id),
                                    onTap: () => context.push(
                                      '/books/${book.id}',
                                      extra: book,
                                    ),
                                    onFavoriteChanged: (favorite) =>
                                        _toggleFavorite(book, favorite),
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _schedulePendingNoticeCheck() {
    if (_noticeCheckScheduled) return;
    _noticeCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _noticeCheckScheduled = false;
      if (!mounted) return;
      final message = context.read<AuthProvider>().takePendingSuccessMessage();
      if (message != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    });
  }
}

class _BookSummary extends StatelessWidget {
  const _BookSummary({required this.summary});

  final BookListSummary summary;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Books: ${summary.bookCount}'),
            const SizedBox(height: 4),
            Text('Favorites: ${summary.favoriteCount}'),
            for (final item in summary.statusCounts)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(item.status)),
                    Text('${item.count}'),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
