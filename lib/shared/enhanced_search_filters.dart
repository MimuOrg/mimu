import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mimu/shared/enhanced_ui_components.dart';
import 'package:mimu/shared/rich_black_animations.dart';

/// Улучшенный поиск с фильтрами и богатым черным дизайном
class EnhancedSearchBar extends StatefulWidget {
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFilterChanged;
  final List<String>? filterOptions;
  final String? selectedFilter;

  const EnhancedSearchBar({
    super.key,
    this.hintText,
    this.onChanged,
    this.onFilterChanged,
    this.filterOptions,
    this.selectedFilter,
  });

  @override
  State<EnhancedSearchBar> createState() => _EnhancedSearchBarState();
}

class _EnhancedSearchBarState extends State<EnhancedSearchBar> {
  late TextEditingController _controller;
  bool _hasText = false;
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _selectedFilter = widget.selectedFilter;
    _controller.addListener(() {
      setState(() => _hasText = _controller.text.isNotEmpty);
      widget.onChanged?.call(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichBlackSearchBar(
          controller: _controller,
          hintText: widget.hintText ?? 'Поиск...',
          onChanged: widget.onChanged,
          onClear: () {
            _controller.clear();
            widget.onChanged?.call('');
          },
        ),
        if (widget.filterOptions != null && widget.filterOptions!.isNotEmpty) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.filterOptions!.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: RichBlackChip(
                    label: filter,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedFilter = isSelected ? null : filter;
                      });
                      widget.onFilterChanged?.call(_selectedFilter ?? '');
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

/// Расширенная сортировка с богатым черным дизайном
class EnhancedSortMenu extends StatelessWidget {
  final List<SortOption> options;
  final SortOption? selectedOption;
  final ValueChanged<SortOption>? onOptionSelected;

  const EnhancedSortMenu({
    super.key,
    required this.options,
    this.selectedOption,
    this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOption>(
      icon: Icon(
        CupertinoIcons.sort_down,
        color: Colors.white.withOpacity(0.8),
      ),
      color: RichBlackPalette.charcoalBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) => options.map((option) {
        final isSelected = selectedOption == option;
        return PopupMenuItem<SortOption>(
          value: option,
          child: RichBlackListTile(
            leading: Icon(
              isSelected ? CupertinoIcons.checkmark : option.icon,
              size: 20,
              color: Colors.white.withOpacity(isSelected ? 0.9 : 0.7),
            ),
            title: Text(option.label),
            isSelected: isSelected,
            onTap: () {
              Navigator.pop(context);
              onOptionSelected?.call(option);
            },
          ),
        );
      }).toList(),
    );
  }
}

class SortOption {
  final String label;
  final IconData icon;
  final String value;

  const SortOption({
    required this.label,
    required this.icon,
    required this.value,
  });
}

/// Улучшенные фильтры с богатым черным дизайном
class EnhancedFilters extends StatefulWidget {
  final List<FilterCategory> categories;
  final Map<String, List<String>> selectedFilters;
  final ValueChanged<Map<String, List<String>>>? onFiltersChanged;

  const EnhancedFilters({
    super.key,
    required this.categories,
    this.selectedFilters = const {},
    this.onFiltersChanged,
  });

  @override
  State<EnhancedFilters> createState() => _EnhancedFiltersState();
}

class _EnhancedFiltersState extends State<EnhancedFilters> {
  late Map<String, List<String>> _selectedFilters;

  @override
  void initState() {
    super.initState();
    _selectedFilters = Map.from(widget.selectedFilters);
  }

  void _toggleFilter(String category, String filter) {
    setState(() {
      if (!_selectedFilters.containsKey(category)) {
        _selectedFilters[category] = [];
      }
      if (_selectedFilters[category]!.contains(filter)) {
        _selectedFilters[category]!.remove(filter);
      } else {
        _selectedFilters[category]!.add(filter);
      }
      if (_selectedFilters[category]!.isEmpty) {
        _selectedFilters.remove(category);
      }
      widget.onFiltersChanged?.call(_selectedFilters);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.categories.map((category) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: RichBlackCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: category.options.map((option) {
                    final isSelected = _selectedFilters[category.key]?.contains(option.value) ?? false;
                    return RichBlackChip(
                      label: option.label,
                      isSelected: isSelected,
                      icon: option.icon,
                      onTap: () => _toggleFilter(category.key, option.value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class FilterCategory {
  final String key;
  final String label;
  final List<FilterOption> options;

  const FilterCategory({
    required this.key,
    required this.label,
    required this.options,
  });
}

class FilterOption {
  final String value;
  final String label;
  final IconData? icon;

  const FilterOption({
    required this.value,
    required this.label,
    this.icon,
  });
}

/// Быстрые действия поиска
class QuickSearchActions extends StatelessWidget {
  final List<QuickAction> actions;
  final ValueChanged<QuickAction>? onActionSelected;

  const QuickSearchActions({
    super.key,
    required this.actions,
    this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: actions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: RichBlackButton(
              icon: action.icon,
              isOutlined: true,
              onPressed: () => onActionSelected?.call(action),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(action.label),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class QuickAction {
  final String label;
  final IconData icon;
  final String value;

  const QuickAction({
    required this.label,
    required this.icon,
    required this.value,
  });
}

