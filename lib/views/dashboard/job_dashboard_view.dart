import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/job_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/job_card.dart';
import '../../widgets/shimmer_card.dart';

class JobDashboardView extends StatefulWidget {
  const JobDashboardView({super.key});

  @override
  State<JobDashboardView> createState() => _JobDashboardViewState();
}

class _JobDashboardViewState extends State<JobDashboardView> {
  final JobController controller = Get.find<JobController>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Infinite scroll listener
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 120) {
        controller.fetchJobs(isRefresh: false);
      }
    });

    // Clear search text if query resets
    ever(controller.searchQuery, (String query) {
      if (query.isEmpty && _searchController.text.isNotEmpty) {
        _searchController.clear();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'HireHub',
          style: theme.textTheme.displayMedium?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // 1. Large Search Bar
              CustomSearchBar(
                controller: _searchController,
                onChanged: controller.setSearchQuery,
              ),
              const SizedBox(height: 16),

              // 2. Category Chips
              _buildCategoryChips(),
              const SizedBox(height: 16),

              // 3. Section Title & Sorting Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Opportunities',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  _buildSortDropdown(theme),
                ],
              ),
              const SizedBox(height: 12),

              // 4. Main content list / shimmers / error screen
              Expanded(
                child: Obx(() {
                  final state = controller.currentState.value;

                  if (state == 'loading' && controller.allJobs.isEmpty) {
                    // Show a list of shimmers during initial load
                    return ListView.builder(
                      itemCount: 4,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) => const ShimmerCard(),
                    );
                  }

                  if (state == 'error' && controller.allJobs.isEmpty) {
                    return _buildErrorState(theme);
                  }

                  if (controller.filteredJobs.isEmpty) {
                    return _buildEmptyState(theme);
                  }

                  return RefreshIndicator(
                    color: AppColors.accent,
                    backgroundColor: AppColors.surface,
                    onRefresh: () => controller.fetchJobs(isRefresh: true),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: controller.filteredJobs.length +
                          (controller.hasMore.value ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == controller.filteredJobs.length) {
                          // Standard bottom spinner during pagination
                          return _buildLoaderIndicatorItem();
                        }

                        final job = controller.filteredJobs[index];
                        return JobCard(job: job);
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortDropdown(ThemeData theme) {
    return Obx(() {
      final selected = controller.selectedSortOption.value;
      IconData sortIcon = Icons.sort;
      if (selected == 'Title (A-Z)' || selected == 'Company (A-Z)') {
        sortIcon = Icons.sort_by_alpha;
      }

      return Theme(
        data: Theme.of(context).copyWith(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: PopupMenuButton<String>(
          offset: const Offset(0, 40),
          tooltip: 'Sort jobs',
          onSelected: controller.selectSortOption,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
          color: AppColors.surface,
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'Newest',
              child: Row(
                children: [
                  Icon(
                    Icons.schedule, 
                    size: 16, 
                    color: selected == 'Newest' ? AppColors.accent : AppColors.secondary
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Newest First',
                    style: TextStyle(
                      color: selected == 'Newest' ? AppColors.accent : AppColors.primary,
                      fontWeight: selected == 'Newest' ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'Title (A-Z)',
              child: Row(
                children: [
                  Icon(
                    Icons.sort_by_alpha, 
                    size: 16, 
                    color: selected == 'Title (A-Z)' ? AppColors.accent : AppColors.secondary
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Job Title (A-Z)',
                    style: TextStyle(
                      color: selected == 'Title (A-Z)' ? AppColors.accent : AppColors.primary,
                      fontWeight: selected == 'Title (A-Z)' ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'Title (Z-A)',
              child: Row(
                children: [
                  Icon(
                    Icons.sort_by_alpha, 
                    size: 16, 
                    color: selected == 'Title (Z-A)' ? AppColors.accent : AppColors.secondary
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Job Title (Z-A)',
                    style: TextStyle(
                      color: selected == 'Title (Z-A)' ? AppColors.accent : AppColors.primary,
                      fontWeight: selected == 'Title (Z-A)' ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'Company (A-Z)',
              child: Row(
                children: [
                  Icon(
                    Icons.business, 
                    size: 16, 
                    color: selected == 'Company (A-Z)' ? AppColors.accent : AppColors.secondary
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Company (A-Z)',
                    style: TextStyle(
                      color: selected == 'Company (A-Z)' ? AppColors.accent : AppColors.primary,
                      fontWeight: selected == 'Company (A-Z)' ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'Company (Z-A)',
              child: Row(
                children: [
                  Icon(
                    Icons.business, 
                    size: 16, 
                    color: selected == 'Company (Z-A)' ? AppColors.accent : AppColors.secondary
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Company (Z-A)',
                    style: TextStyle(
                      color: selected == 'Company (Z-A)' ? AppColors.accent : AppColors.primary,
                      fontWeight: selected == 'Company (Z-A)' ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(sortIcon, size: 18, color: AppColors.accent),
              const SizedBox(width: 4),
              Text(
                selected,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.accent),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCategoryChips() {
    final categories = ['All', 'Software Eng', 'Data Science', 'Design', 'Operations'];

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Obx(() {
            final isSelected = controller.selectedCategory.value == cat;
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => controller.selectCategory(cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected ? AppColors.accent : AppColors.surface,
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppColors.secondary,
                    ),
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildLoaderIndicatorItem() {
    return Obx(() {
      if (controller.isLoadingMore.value) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'LOADING MORE OPPORTUNITIES...',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 48, color: AppColors.secondary),
              const SizedBox(height: 16),
              Text(
                'No jobs found',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'We couldn\'t find any openings matching your query.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.secondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off,
                color: AppColors.accent,
                size: 44,
              ),
              const SizedBox(height: 16),
              Text(
                'NO INTERNET CONNECTION',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your network credentials. We were unable to sync with HireHub recruiting servers.',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () => controller.fetchJobs(isRefresh: true),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'RETRY CONNECTION',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
