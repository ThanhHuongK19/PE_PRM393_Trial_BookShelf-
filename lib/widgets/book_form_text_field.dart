import 'package:flutter/material.dart';

class BookFormTextField extends StatelessWidget {
  const BookFormTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
    required this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.sentences,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}
