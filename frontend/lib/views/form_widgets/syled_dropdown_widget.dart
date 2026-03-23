import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';

class StyledDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  const StyledDropdown({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.input,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
            size: 20,
          ),
          style: AppTextStyles.inputText,
          onChanged: (newValue) {
            if (newValue != null) onChanged(newValue);
          },
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(labelBuilder(item)),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}