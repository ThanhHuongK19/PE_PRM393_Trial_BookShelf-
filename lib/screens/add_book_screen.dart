import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../services/book_service.dart';
import '../validators/book_validators.dart';
import '../widgets/book_form_text_field.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _ratingController = TextEditingController();
  final _notesController = TextEditingController();

  String? _genre;
  String? _status;
  int _formVersion = 0;
  bool _hasSubmitted = false;
  bool _isSaving = false;
  String? _submitError;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _ratingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _clearSubmitError() {
    if (_submitError != null) setState(() => _submitError = null);
  }

  Future<void> _submit() async {
    setState(() {
      _hasSubmitted = true;
      _submitError = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final ratingText = _ratingController.text.trim();
      await context.read<BookService>().createBook(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        genre: _genre!,
        status: _status!,
        rating: ratingText.isEmpty ? null : int.parse(ratingText),
        favorite: false,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      _clearForm();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Book added')));
    } catch (error) {
      if (mounted) setState(() => _submitError = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _authorController.clear();
    _ratingController.clear();
    _notesController.clear();
    _formKey.currentState?.reset();
    setState(() {
      _genre = null;
      _status = null;
      _formVersion++;
      _hasSubmitted = false;
      _submitError = null;
    });
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add Book')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
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
                      key: ValueKey('genre-$_formVersion'),
                      initialValue: _genre,
                      decoration: const InputDecoration(
                        labelText: 'Genre',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Choose genre'),
                        ),
                        ...Book.genres.map(
                          (genre) => DropdownMenuItem(
                            value: genre,
                            child: Text(genre),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _genre = value);
                        _clearSubmitError();
                      },
                      validator: BookValidators.genre,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey('status-$_formVersion'),
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Choose status'),
                        ),
                        ...Book.statuses.map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        ),
                      ],
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
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Add Book'),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
