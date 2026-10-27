import 'package:bookshelf/validators/auth_validators.dart';
import 'package:bookshelf/validators/book_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('authentication validation messages', () {
    test('email and password messages match the exam', () {
      expect(AuthValidators.email(''), 'Email is required');
      expect(
        AuthValidators.email('not-an-email'),
        'Please enter a valid email address',
      );
      expect(AuthValidators.password(''), 'Password is required');
      expect(
        AuthValidators.password('12345'),
        'Password must be at least 6 characters',
      );
      expect(AuthValidators.loginPassword('12345'), isNull);
    });

    test('confirm password messages match the exam', () {
      expect(
        AuthValidators.confirmPassword('', 'secret'),
        'Confirm password is required',
      );
      expect(
        AuthValidators.confirmPassword('different', 'secret'),
        'Passwords do not match',
      );
    });
  });

  group('book validation messages', () {
    test('required text and length messages match the exam', () {
      expect(BookValidators.title('  '), 'Title is required');
      expect(
        BookValidators.title(List.filled(101, 't').join()),
        'Title must be at most 100 characters',
      );
      expect(BookValidators.author('  '), 'Author is required');
      expect(
        BookValidators.author(List.filled(61, 'a').join()),
        'Author must be at most 60 characters',
      );
      expect(BookValidators.genre(null), 'Please choose a genre');
      expect(BookValidators.status(null), 'Please choose a status');
    });

    test('optional field validation messages match the exam', () {
      expect(
        BookValidators.rating('2.5'),
        'Rating must be a whole number from 0 to 5',
      );
      expect(BookValidators.rating(''), isNull);
      expect(
        BookValidators.notes(List.filled(301, 'n').join()),
        'Notes must be at most 300 characters',
      );
    });
  });
}
