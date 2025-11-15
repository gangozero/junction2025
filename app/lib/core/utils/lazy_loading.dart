/// Lazy loading pagination helpers
library;

import 'package:flutter/material.dart';

/// Paginated list state
class PaginatedListState<T> {
  final List<T> items;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int currentPage;

  const PaginatedListState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
  });

  PaginatedListState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? currentPage,
  }) {
    return PaginatedListState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Lazy loading scroll controller
///
/// Automatically triggers loading when scrolling near the bottom
class LazyLoadingScrollController extends ScrollController {
  final VoidCallback onLoadMore;
  final double loadThreshold;

  LazyLoadingScrollController({
    required this.onLoadMore,
    this.loadThreshold = 200.0,
  }) {
    addListener(_scrollListener);
  }

  void _scrollListener() {
    if (position.pixels >= position.maxScrollExtent - loadThreshold) {
      onLoadMore();
    }
  }

  @override
  void dispose() {
    removeListener(_scrollListener);
    super.dispose();
  }
}

/// Lazy loading list view
///
/// Displays paginated list with automatic loading on scroll
class LazyLoadingListView<T> extends StatefulWidget {
  final PaginatedListState<T> state;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final VoidCallback onLoadMore;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  const LazyLoadingListView({
    super.key,
    required this.state,
    required this.itemBuilder,
    required this.onLoadMore,
    this.emptyWidget,
    this.errorWidget,
    this.loadingWidget,
    this.padding,
    this.physics,
  });

  @override
  State<LazyLoadingListView<T>> createState() => _LazyLoadingListViewState<T>();
}

class _LazyLoadingListViewState<T> extends State<LazyLoadingListView<T>> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = LazyLoadingScrollController(
      onLoadMore: _handleLoadMore,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleLoadMore() {
    if (!widget.state.isLoading && widget.state.hasMore) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show error state
    if (widget.state.error != null && widget.state.items.isEmpty) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(widget.state.error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: widget.onLoadMore,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
    }

    // Show empty state
    if (widget.state.items.isEmpty && !widget.state.isLoading) {
      return widget.emptyWidget ?? const Center(child: Text('No items found'));
    }

    // Show loading state (first page)
    if (widget.state.items.isEmpty && widget.state.isLoading) {
      return widget.loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    // Show list with items
    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      physics: widget.physics,
      itemCount: widget.state.items.length + (widget.state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at bottom
        if (index == widget.state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Show item
        return widget.itemBuilder(context, widget.state.items[index], index);
      },
    );
  }
}

/// Pagination helper mixin
///
/// Add to StateNotifier to enable pagination logic
mixin PaginationMixin<T> {
  static const int defaultPageSize = 20;

  /// Load next page of items
  Future<List<T>> loadPage(int page, int pageSize);

  /// Calculate if there are more pages
  bool hasMorePages(int currentPage, int pageSize, int totalItems) {
    return (currentPage + 1) * pageSize < totalItems;
  }

  /// Merge new items with existing items
  List<T> mergeItems(List<T> existing, List<T> newItems, {bool append = true}) {
    if (append) {
      return [...existing, ...newItems];
    } else {
      return [...newItems, ...existing];
    }
  }
}

/// Infinite scroll pagination
///
/// Alternative implementation using flutter's built-in pagination
class InfiniteScrollList<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final bool isLoading;
  final Widget? loadingIndicator;
  final EdgeInsetsGeometry? padding;

  const InfiniteScrollList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onLoadMore,
    this.hasMore = true,
    this.isLoading = false,
    this.loadingIndicator,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!isLoading &&
            hasMore &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          onLoadMore?.call();
        }
        return false;
      },
      child: ListView.builder(
        padding: padding,
        itemCount: items.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return loadingIndicator ??
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
          }
          return itemBuilder(context, items[index]);
        },
      ),
    );
  }
}
