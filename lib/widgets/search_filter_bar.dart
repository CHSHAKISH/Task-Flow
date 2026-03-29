import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task_flow/models/task.dart';
import 'package:task_flow/theme/app_theme.dart';
import 'package:task_flow/utils/debouncer.dart';

/// Premium search bar + filter chips with 300ms debounce (stretch goal).
class SearchFilterBar extends StatefulWidget {
  final String searchQuery;
  final TaskStatus? selectedFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<TaskStatus?> onFilterChanged;

  const SearchFilterBar({
    super.key,
    required this.searchQuery,
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  final _searchController = TextEditingController();
  // 300ms debounce as required by the stretch goal spec
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {}); // rebuild for clear icon visibility
    _debouncer.call(() => widget.onSearchChanged(query));
  }

  void _clearSearch() {
    _searchController.clear();
    _debouncer.cancel();
    widget.onSearchChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search Bar ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search tasks by title or description…',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.grey.shade400,
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.cancel_rounded,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      onPressed: _clearSearch,
                    )
                  : null,
            ),
            onChanged: _onSearchChanged,
          ),
        ),

        // ── Filter Chips ────────────────────────────────────────────────────
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _FilterChip(
                label: 'All',
                selected: widget.selectedFilter == null,
                color: AppTheme.primarySeed,
                onTap: () => widget.onFilterChanged(null),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'To Do',
                selected: widget.selectedFilter == TaskStatus.todo,
                color: AppTheme.todo,
                onTap: () => widget.onFilterChanged(
                  widget.selectedFilter == TaskStatus.todo
                      ? null
                      : TaskStatus.todo,
                ),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'In Progress',
                selected: widget.selectedFilter == TaskStatus.inProgress,
                color: AppTheme.inProgress,
                onTap: () => widget.onFilterChanged(
                  widget.selectedFilter == TaskStatus.inProgress
                      ? null
                      : TaskStatus.inProgress,
                ),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Done',
                selected: widget.selectedFilter == TaskStatus.done,
                color: AppTheme.done,
                onTap: () => widget.onFilterChanged(
                  widget.selectedFilter == TaskStatus.done
                      ? null
                      : TaskStatus.done,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }
}

/// Custom, tappable filter chip with colorful selected state.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : Colors.grey.shade300,
              width: selected ? 0 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withAlpha(64),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey.shade600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
