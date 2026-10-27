class BookValidators {
  static String? title(String? value) {
    final title = value ?? '';
    if (title.trim().isEmpty) return 'Title is required';
    if (title.length > 100) return 'Title must be at most 100 characters';
    return null;
  }

  static String? author(String? value) {
    final author = value ?? '';
    if (author.trim().isEmpty) return 'Author is required';
    if (author.length > 60) return 'Author must be at most 60 characters';
    return null;
  }

  static String? genre(String? value) =>
      value == null ? 'Please choose a genre' : null;

  static String? status(String? value) =>
      value == null ? 'Please choose a status' : null;

  static String? rating(String? value) {
    final rating = value?.trim() ?? '';
    if (rating.isEmpty) return null;
    final parsed = int.tryParse(rating);
    if (parsed == null || parsed < 0 || parsed > 5) {
      return 'Rating must be a whole number from 0 to 5';
    }
    return null;
  }

  static String? notes(String? value) {
    if ((value ?? '').length > 300) return 'Notes must be at most 300 characters';
    return null;
  }
}
