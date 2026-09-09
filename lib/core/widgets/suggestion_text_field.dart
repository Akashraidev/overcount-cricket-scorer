import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_text_styles.dart';

class SuggestionTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String prefKey;
  final List<String> defaultSuggestions;
  final IconData prefixIcon;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const SuggestionTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.prefKey,
    required this.defaultSuggestions,
    this.prefixIcon = Icons.edit,
    this.onChanged,
    this.validator,
  });

  @override
  State<SuggestionTextField> createState() => _SuggestionTextFieldState();
}

class _SuggestionTextFieldState extends State<SuggestionTextField> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showOverlay();
      } else {
        _hideOverlay();
        _saveCurrentValue();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _hideOverlay();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(widget.prefKey);
    if (saved != null && saved.isNotEmpty) {
      final merged = List<String>.from(saved);
      for (final def in widget.defaultSuggestions) {
        if (!merged.contains(def)) {
          merged.add(def);
        }
      }
      _suggestions = merged;
      await prefs.setStringList(widget.prefKey, _suggestions);
    } else {
      _suggestions = List<String>.from(widget.defaultSuggestions);
      await prefs.setStringList(widget.prefKey, _suggestions);
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveCurrentValue() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    if (!_suggestions.contains(text)) {
      _suggestions.insert(0, text);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(widget.prefKey, _suggestions);
      if (mounted) setState(() {});
    }
  }

  Future<void> _deleteSuggestion(String item) async {
    _suggestions.remove(item);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(widget.prefKey, _suggestions);
    if (mounted) {
      setState(() {});
      _updateOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;

    return OverlayEntry(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Positioned(
          width: size.width > 0 ? size.width : 320,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0.0, size.height + 6.0),
            child: Material(
              elevation: 8,
              borderRadius: AppRadius.roundedMd,
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.roundedMd,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: _suggestions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('No suggestions available', style: TextStyle(fontSize: 12)),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                        itemBuilder: (context, index) {
                          final item = _suggestions[index];
                          return InkWell(
                            onTap: () {
                              widget.controller.text = item;
                              widget.onChanged?.call(item);
                              _focusNode.unfocus();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    widget.prefixIcon,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontSize: 13,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    splashRadius: 16,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                    tooltip: 'Remove suggestion',
                                    onPressed: () => _deleteSuggestion(item),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: AppTextStyles.label.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              if (_suggestions.isNotEmpty)
                Text(
                  'Tap for suggestions',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            validator: widget.validator,
            onChanged: (v) {
              widget.onChanged?.call(v);
            },
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: Icon(widget.prefixIcon, size: 20),
              suffixIcon: widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        widget.controller.clear();
                        widget.onChanged?.call('');
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
