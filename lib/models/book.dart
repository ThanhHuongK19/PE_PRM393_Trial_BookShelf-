import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  const Book({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    required this.rating,
    required this.favorite,
    required this.notes,
    required this.createdAt,
  });

  static const int maxIdLength = 1500;
  static const int maxUserIdLength = 128;
  static const int maxTitleLength = 100;
  static const int maxAuthorLength = 60;
  static const int maxGenreLength = 50;
  static const int maxStatusLength = 30;
  static const int maxNotesLength = 300;
  static const genres = ['Fiction', 'Non-Fiction', 'Academic', 'Other'];
  static const statuses = ['To Read', 'Reading', 'Finished'];

  final String id;
  final String userId;
  final String title;
  final String author;
  final String genre;
  final String status;
  final int? rating;
  final bool favorite;
  final String notes;
  final DateTime createdAt;

  Book copyWith({bool? favorite}) => Book(
    id: id,
    userId: userId,
    title: title,
    author: author,
    genre: genre,
    status: status,
    rating: rating,
    favorite: favorite ?? this.favorite,
    notes: notes,
    createdAt: createdAt,
  );

  factory Book.fromMap(Map<String, dynamic> map) {
    final rawCreatedAt = map['createdAt'];
    final createdAt = switch (rawCreatedAt) {
      Timestamp value => value.toDate(),
      DateTime value => value,
      _ => throw const FormatException('createdAt must be a Firestore timestamp.'),
    };

    final rawRating = map['rating'];
    final int? rating;
    if (!map.containsKey('rating')) {
      rating = null;
    } else if (rawRating is int) {
      rating = rawRating;
    } else {
      throw const FormatException('rating must be a whole number from 0 to 5.');
    }

    final book = Book(
      id: _stringField(map, 'id'),
      userId: _stringField(map, 'userId'),
      title: _stringField(map, 'title'),
      author: _stringField(map, 'author'),
      genre: _stringField(map, 'genre'),
      status: _stringField(map, 'status'),
      rating: rating,
      favorite: _boolField(map, 'favorite'),
      notes: _stringField(map, 'notes'),
      createdAt: createdAt,
    );
    book.validate();
    return book;
  }

  Map<String, dynamic> toMap() {
    validate();
    final data = <String, dynamic>{
      'id': id,
      'userId': userId,
      'title': title,
      'author': author,
      'genre': genre,
      'status': status,
      'favorite': favorite,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
    if (rating != null) data['rating'] = rating;
    return data;
  }

  void validate() {
    _validateText('id', id, maxIdLength);
    _validateText('userId', userId, maxUserIdLength);
    _validateText('title', title, maxTitleLength);
    _validateText('author', author, maxAuthorLength);
    if (!genres.contains(genre)) {
      throw const FormatException('genre must be a supported genre.');
    }
    if (!statuses.contains(status)) {
      throw const FormatException('status must be a supported status.');
    }
    _validateText('notes', notes, maxNotesLength, allowEmpty: true);

    final bookRating = rating;
    if (bookRating != null && (bookRating < 0 || bookRating > 5)) {
      throw const FormatException('rating must be a whole number from 0 to 5.');
    }
  }

  static String _stringField(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value is! String) {
      throw FormatException('$field must be a string.');
    }
    return value;
  }

  static bool _boolField(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value is! bool) {
      throw FormatException('$field must be a boolean.');
    }
    return value;
  }

  static void _validateText(
    String field,
    String value,
    int maxLength, {
    bool allowEmpty = false,
  }) {
    if ((!allowEmpty && value.trim().isEmpty) || value.length > maxLength) {
      throw FormatException(
        '$field must ${allowEmpty ? 'be at most' : 'contain 1 to'} '
        '$maxLength characters${allowEmpty ? '' : ' and cannot be blank'}.',
      );
    }
  }
}
