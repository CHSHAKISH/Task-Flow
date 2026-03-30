import 'dart:async';
import 'package:flutter/material.dart';
import 'package:task_flow/models/task.dart';

/// SearchFilterBar widget provides search and filter functionality
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
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onSearchChanged(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search TextField
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search tasks...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        widget.onSearchChanged('');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {}); // Update clear button visibility
              _onSearchChanged(value);
            },
          ),
        ),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: widget.selectedFilter == null,
                onSelected: (selected) {
                  if (selected) widget.onFilterChanged(null);
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('To Do'),
                selected: widget.selectedFilter == TaskStatus.todo,
                onSelected: (selected) {
                  widget.onFilterChanged(selected ? TaskStatus.todo : null);
                },
                avatar: Icon(
                  Icons.circle,
                  size: 12,
                  color: widget.selectedFilter == TaskStatus.todo
                      ? Colors.white
                      : Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('In Progress'),
                selected: widget.selectedFilter == TaskStatus.inProgress,
                onSelected: (selected) {
                  widget.onFilterChanged(
                      selected ? TaskStatus.inProgress : null);
                },
                avatar: Icon(
                  Icons.circle,
                  size: 12,
                  color: widget.selectedFilter == TaskStatus.inProgress
                      ? Colors.white
                      : Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Done'),
                selected: widget.selectedFilter == TaskStatus.done,
                onSelected: (selected) {
                  widget.onFilterChanged(selected ? TaskStatus.done : null);
                },
                avatar: Icon(
                  Icons.circle,
                  size: 12,
                  color: widget.selectedFilter == TaskStatus.done
                      ? Colors.white
                      : Colors.green,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
