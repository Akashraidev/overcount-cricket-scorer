import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class AppDropdown<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final IconData? prefixIcon;

  const AppDropdown({
    super.key,
    this.label,
    this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
  });

  String _getItemLabel(DropdownMenuItem<T> item) {
    if (item.child is Text) {
      return (item.child as Text).data ?? '';
    }
    return item.value?.toString() ?? '';
  }

  void _openSelectSheet(BuildContext context, FormFieldState<T> state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Deduplicate items by value
    final seen = <T?>{};
    final uniqueItems = <DropdownMenuItem<T>>[];
    for (final item in items) {
      if (seen.add(item.value)) {
        uniqueItems.add(item);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredItems = searchQuery.isEmpty
                ? uniqueItems
                : uniqueItems.where((item) {
                    final text = _getItemLabel(item).toLowerCase();
                    return text.contains(searchQuery.toLowerCase());
                  }).toList();

            final screenHeight = MediaQuery.of(sheetContext).size.height;
            final maxSheetHeight = screenHeight * 0.75;

            return Container(
              constraints: BoxConstraints(maxHeight: maxSheetHeight),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1.5,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle pill
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 8),
                        width: 40,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
                      child: Row(
                        children: [
                          if (prefixIcon != null) ...[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(prefixIcon, size: 20, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label ?? hint ?? 'Select Option',
                                  style: AppTextStyles.h3.copyWith(
                                    fontSize: 17,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                if (label != null && hint != null)
                                  Text(
                                    hint!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.pop(sheetContext),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ),

                    // Search box if more than 5 items
                    if (uniqueItems.length > 5) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: TextField(
                            autofocus: false,
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              hintStyle: AppTextStyles.bodyMedium.copyWith(
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onChanged: (val) => setSheetState(() => searchQuery = val),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    const Divider(height: 1),

                    // Items list
                    Flexible(
                      child: filteredItems.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Center(
                                child: Text(
                                  'No options found',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shrinkWrap: true,
                              itemCount: filteredItems.length,
                              separatorBuilder: (_, index) => const SizedBox(height: 6),
                              itemBuilder: (context, idx) {
                                final item = filteredItems[idx];
                                final isSelected = item.value == value;

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      Navigator.pop(sheetContext);
                                      state.didChange(item.value);
                                      onChanged?.call(item.value);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary.withValues(alpha: 0.12)
                                            : (isDark
                                                ? AppColors.darkSurfaceElevated.withValues(alpha: 0.4)
                                                : AppColors.lightSurfaceElevated),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: DefaultTextStyle(
                                              style: AppTextStyles.bodyMedium.copyWith(
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : (isDark
                                                        ? AppColors.darkTextPrimary
                                                        : AppColors.lightTextPrimary),
                                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                              ),
                                              child: item.child,
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              size: 22,
                                              color: AppColors.primary,
                                            )
                                          else
                                            Icon(
                                              Icons.circle_outlined,
                                              size: 20,
                                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fillColor = isDark
        ? AppColors.darkSurfaceElevated.withValues(alpha: 0.5)
        : AppColors.lightSurfaceElevated;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        final hasError = state.hasError;
        final selectedItem = items.where((i) => i.value == value).firstOrNull;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null) ...[
              Text(
                label!,
                style: AppTextStyles.label.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 7),
            ],
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onChanged == null ? null : () => _openSelectSheet(context, state),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasError ? AppColors.error : borderColor,
                    width: hasError ? 1.5 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (prefixIcon != null) ...[
                      Icon(
                        prefixIcon,
                        size: 20,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: selectedItem != null
                          ? DefaultTextStyle(
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              child: selectedItem.child,
                            )
                          : Text(
                              hint ?? 'Select...',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primary.withValues(alpha: 0.18)
                            : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (hasError && state.errorText != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  state.errorText!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
