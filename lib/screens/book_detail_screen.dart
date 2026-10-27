import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../providers/auth_provider.dart';
import '../services/book_service.dart';
import '../validators/book_validators.dart';
import '../widgets/book_form_text_field.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key, required this.bookId, this.book});

  final String bookId;
  final Book? book;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _hasLoadedForUser = false;
  String? _loadedForUserId;
  Future<Book?>? _bookFuture;

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.uid;
    final canUsePassedBook =
        widget.book != null && widget.book!.userId == userId;
    if (!canUsePassedBook &&
        (!_hasLoadedForUser || _loadedForUserId != userId)) {
      _hasLoadedForUser = true;
      _loadedForUserId = userId;
      _bookFuture = userId == null
          ? Future<Book?>.value(null)
          : context.read<BookService>().getBook(widget.bookId);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Book details')),
      body: canUsePassedBook
          ? _BookDetails(key: ValueKey(widget.book!.id), book: widget.book!)
          : FutureBuilder<Book?>(
              future: _bookFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Could not load this book.'));
                }
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final book = snapshot.data;
                if (book == null) {
                  return const Center(child: Text('Book not found.'));
                }
                return _BookDetails(key: ValueKey(book.id), book: book);
              },
            ),
    );
  }
}

class _BookDetails extends StatefulWidget {
  const _BookDetails({super.key, required this.book});

  final Book book;

  @override
  State<_BookDetails> createState() => _BookDetailsState();
}

class _BookDetailsState extends State<_BookDetails> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _ratingController;
  late final TextEditingController _notesController;

  late Book _book;
  String? _genre;
  String? _status;
  bool _isEditing = false;
  bool _hasSubmitted = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isUpdatingFavorite = false;
  String? _submitError;
  int _formVersion = 0;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _titleController = TextEditingController(text: _book.title);
    _authorController = TextEditingController(text: _book.author);
    _ratingController = TextEditingController(
      text: _book.rating?.toString() ?? '',
    );
    _notesController = TextEditingController(text: _book.notes);
    _genre = _book.genre;
    _status = _book.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _ratingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _startEditing() {
    _titleController.text = _book.title;
    _authorController.text = _book.author;
    _ratingController.text = _book.rating?.toString() ?? '';
    _notesController.text = _book.notes;
    setState(() {
      _genre = _book.genre;
      _status = _book.status;
      _hasSubmitted = false;
      _submitError = null;
      _formVersion++;
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _hasSubmitted = false;
      _submitError = null;
    });
  }

  Future<void> _save() async {
    setState(() {
      _hasSubmitted = true;
      _submitError = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final ratingText = _ratingController.text.trim();
      final updatedBook = Book(
        id: _book.id,
        userId: _book.userId,
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        genre: _genre!,
        status: _status!,
        rating: ratingText.isEmpty ? null : int.parse(ratingText),
        favorite: _book.favorite,
        notes: _notesController.text.trim(),
        createdAt: _book.createdAt,
      );
      await context.read<BookService>().updateBook(updatedBook);
      if (!mounted) return;
      setState(() {
        _book = updatedBook;
        _isEditing = false;
        _hasSubmitted = false;
      });
      _showMessage('Book updated');
    } catch (error) {
      if (mounted) setState(() => _submitError = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final wasFavorite = _book.favorite;
    setState(() {
      _book = _book.copyWith(favorite: !wasFavorite);
      _isUpdatingFavorite = true;
    });
    try {
      await context.read<BookService>().setFavorite(
        _book.id,
        favorite: _book.favorite,
      );
    } catch (error) {
      if (mounted) {
        setState(() => _book = _book.copyWith(favorite: wasFavorite));
        _showMessage(_errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _isUpdatingFavorite = false);
    }
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete book?'),
        content: Text('Delete "${_book.title}" from your library?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await context.read<BookService>().deleteBook(_book.id);
      if (mounted) context.go('/home');
    } catch (error) {
      if (mounted) _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorMessage(Object error) {
    if (error is FirebaseException && error.message != null) {
      return error.message!;
    }
    if (error is StateError) return error.message.toString();
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) return _buildEditForm(context);
    return _buildReadOnlyDetails(context);
  }

  Widget _buildReadOnlyDetails(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            tooltip: _book.favorite
                ? 'Remove from favorites'
                : 'Add to favorites',
            onPressed: _isUpdatingFavorite ? null : _toggleFavorite,
            icon: Icon(
              _book.favorite ? Icons.star : Icons.star_border,
              color: _book.favorite ? Colors.amber : null,
            ),
          ),
          IconButton(
            tooltip: 'Edit book',
            onPressed: _isDeleting ? null : _startEditing,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete book',
            onPressed: _isDeleting ? null : _confirmDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      Icon(
        Icons.menu_book_rounded,
        size: 64,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: 16),
      Text(
        _book.title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 8),
      Text(
        _book.author,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 28),
      _DetailRow(label: 'ID', value: _book.id),
      _DetailRow(label: 'User ID', value: _book.userId),
      _DetailRow(label: 'Title', value: _book.title),
      _DetailRow(label: 'Author', value: _book.author),
      _DetailRow(label: 'Genre', value: _book.genre),
      _DetailRow(label: 'Status', value: _book.status),
      _DetailRow(
        label: 'Rating',
        value: _book.rating?.toString() ?? 'Not rated',
      ),
      _DetailRow(label: 'Favorite', value: _book.favorite ? 'Yes' : 'No'),
      _DetailRow(
        label: 'Notes',
        value: _book.notes.isEmpty ? 'None' : _book.notes,
      ),
      _DetailRow(
        label: 'Created at',
        value: _book.createdAt.toLocal().toString(),
      ),
    ],
  );

  Widget _buildEditForm(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            autovalidateMode: _hasSubmitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BookFormTextField(
                  controller: _titleController,
                  label: 'Title',
                  validator: BookValidators.title,
                  onChanged: (_) => _clearSubmitError(),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                BookFormTextField(
                  controller: _authorController,
                  label: 'Author',
                  validator: BookValidators.author,
                  onChanged: (_) => _clearSubmitError(),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey('edit-genre-$_formVersion'),
                  initialValue: _genre,
                  decoration: const InputDecoration(
                    labelText: 'Genre',
                    border: OutlineInputBorder(),
                  ),
                  items: Book.genres
                      .map(
                        (genre) =>
                            DropdownMenuItem(value: genre, child: Text(genre)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _genre = value);
                    _clearSubmitError();
                  },
                  validator: BookValidators.genre,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey('edit-status-$_formVersion'),
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: Book.statuses
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _status = value);
                    _clearSubmitError();
                  },
                  validator: BookValidators.status,
                ),
                const SizedBox(height: 16),
                BookFormTextField(
                  controller: _ratingController,
                  label: 'Rating (optional)',
                  validator: BookValidators.rating,
                  onChanged: (_) => _clearSubmitError(),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  textCapitalization: TextCapitalization.none,
                ),
                const SizedBox(height: 16),
                BookFormTextField(
                  controller: _notesController,
                  label: 'Notes (optional)',
                  validator: BookValidators.notes,
                  onChanged: (_) => _clearSubmitError(),
                  maxLines: 4,
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _submitError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _cancelEditing,
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  void _clearSubmitError() {
    if (_submitError != null) setState(() => _submitError = null);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        SelectableText(value),
      ],
    ),
  );
}
