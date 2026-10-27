import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/book.dart';

/// Firestore access for the single `books` collection.
///
/// Duplicate title/author checks are client-side prechecks. Firestore Rules
/// cannot enforce a case-insensitive uniqueness constraint across documents;
/// concurrent clients or direct writes can still create duplicates.
class BookService {
  BookService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _books =>
      _firestore.collection('books');

  Future<Book> createBook({
    required String title,
    required String author,
    required String genre,
    required String status,
    int? rating,
    bool favorite = false,
    String notes = '',
  }) async {
    final userId = _currentUserId;
    await _ensureNoDuplicate(title, author);

    final reference = _books.doc();
    final book = Book(
      id: reference.id,
      userId: userId,
      title: title,
      author: author,
      genre: genre,
      status: status,
      rating: rating,
      favorite: favorite,
      notes: notes,
      createdAt: DateTime.now(),
    );
    book.validate();
    await reference.set(book.toMap());
    return book;
  }

  /// Reads only the signed-in user's books.
  Stream<List<Book>> watchBooks() {
    final userId = _currentUserId;
    return _books
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final book = Book.fromMap(doc.data());
              _ensureDocumentId(doc.id, book);
              return book;
            }).toList());
  }

  /// A document lookup uses its exact path; ownership is checked before return.
  Future<Book?> getBook(String id) async {
    final userId = _currentUserId;
    final snapshot = await _books.doc(id).get();
    if (!snapshot.exists) return null;

    final book = Book.fromMap(snapshot.data()!);
    _ensureDocumentId(snapshot.id, book);
    return book.userId == userId ? book : null;
  }

  Future<void> updateBook(Book book) async {
    final userId = _currentUserId;
    book.validate();
    if (book.userId != userId) {
      throw StateError('A book can only be updated by its owner.');
    }

    final reference = _books.doc(book.id);
    final existing = await reference.get();
    if (!existing.exists) throw StateError('Book does not exist.');
    final existingBook = Book.fromMap(existing.data()!);
    _ensureDocumentId(existing.id, existingBook);
    if (existingBook.userId != userId) {
      throw StateError('A book can only be updated by its owner.');
    }

    await _ensureNoDuplicate(book.title, book.author, excludingId: book.id);
    final data = book.toMap();
    // Preserve the original creation timestamp on updates.
    data['createdAt'] = existing.data()!['createdAt'];
    if (book.rating == null) data['rating'] = FieldValue.delete();
    await reference.update(data);
  }

  Future<void> setFavorite(String id, {required bool favorite}) async {
    if (_auth.currentUser?.uid.isNotEmpty != true) {
      throw StateError('Sign in before accessing books.');
    }
    // Firestore applies this update locally at once; security rules verify
    // document ownership and the id field before accepting it on the server.
    await _books.doc(id).update({'favorite': favorite});
  }

  Future<void> deleteBook(String id) async {
    final userId = _currentUserId;
    final reference = _books.doc(id);
    final existing = await reference.get();
    if (!existing.exists) return;

    final book = Book.fromMap(existing.data()!);
    _ensureDocumentId(existing.id, book);
    if (book.userId != userId) {
      throw StateError('A book can only be deleted by its owner.');
    }
    await reference.delete();
  }

  String get _currentUserId {
    final userId = _auth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      throw StateError('Sign in before accessing books.');
    }
    return userId;
  }

  Future<void> _ensureNoDuplicate(
    String title,
    String author, {
    String? excludingId,
  }) async {
    final userId = _currentUserId;
    final normalizedTitle = _normalize(title);
    final normalizedAuthor = _normalize(author);
    final snapshot = await _books.where('userId', isEqualTo: userId).get();

    for (final document in snapshot.docs) {
      if (document.id == excludingId) continue;
      final data = document.data();
      if (_normalize(data['title'] as String) == normalizedTitle &&
          _normalize(data['author'] as String) == normalizedAuthor) {
        throw StateError('This title and author are already in your library.');
      }
    }
  }

  String _normalize(String value) => value.trim().toLowerCase();

  void _ensureDocumentId(String documentId, Book book) {
    if (documentId != book.id) {
      throw StateError('Firestore document ID must match the book id field.');
    }
  }
}
