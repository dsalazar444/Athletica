import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';

// ─────────────────────────────────────────────
//  SHARED FORM WIDGETS
// ─────────────────────────────────────────────
class FormFieldLabel extends StatelessWidget {
  final String label;
  final bool isRequired;

  const FormFieldLabel({required this.label, this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.label),
        if (isRequired) const Text(' *', style: AppTextStyles.labelRequired),
      ],
    );
  }
}
