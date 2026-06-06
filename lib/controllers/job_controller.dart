import 'dart:async';
import 'package:get/get.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';

class JobController extends GetxController {
  final ApiService _apiService = ApiService();

  // State: 'success', 'loading', 'error'
  final RxString currentState = 'loading'.obs;

  // Jobs state lists
  final RxList<JobModel> allJobs = <JobModel>[].obs;
  final RxList<JobModel> filteredJobs = <JobModel>[].obs;

  // Filters
  final RxString selectedCategory = 'All'.obs;
  final RxString searchQuery = ''.obs;

  // Sorting: 'Newest', 'Title (A-Z)', 'Company (A-Z)'
  final RxString selectedSortOption = 'Newest'.obs;

  // Pagination state
  final RxInt currentPage = 1.obs;
  final RxBool hasMore = true.obs;
  final RxBool isLoadingMore = false.obs;

  // Bookmark count helper
  int get bookmarkCount => allJobs.where((j) => j.isBookmarked).length;

  @override
  void onInit() {
    super.onInit();
    fetchJobs(isRefresh: true);
  }

  Future<void> fetchJobs({bool isRefresh = false}) async {
    if (isRefresh) {
      currentPage.value = 1;
      hasMore.value = true;
      currentState.value = 'loading';
      allJobs.clear();
      filteredJobs.clear();
    } else {
      if (isLoadingMore.value || !hasMore.value) return;
      isLoadingMore.value = true;
    }

    try {
      final newJobs = await _apiService.fetchJobs(page: currentPage.value);
      if (newJobs.isEmpty) {
        hasMore.value = false;
      } else {
        // Dedup if items already exist
        final existingIds = allJobs.map((j) => j.id).toSet();
        final dedupedNewJobs = newJobs.where((j) => !existingIds.contains(j.id)).toList();
        
        if (dedupedNewJobs.isEmpty) {
          hasMore.value = false;
        } else {
          allJobs.addAll(dedupedNewJobs);
          applyFilters();
          currentPage.value++;
        }
      }
      currentState.value = 'success';
    } catch (e) {
      if (isRefresh || allJobs.isEmpty) {
        currentState.value = 'error';
      } else {
        Get.snackbar(
          'Error',
          'Failed to load more jobs. Check your internet connection.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      isLoadingMore.value = false;
    }
  }

  void selectCategory(String category) {
    selectedCategory.value = category;
    applyFilters();
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  void selectSortOption(String option) {
    selectedSortOption.value = option;
    applyFilters();
  }

  void applyFilters() {
    final query = searchQuery.value.toLowerCase();
    final category = selectedCategory.value;

    final filtered = allJobs.where((job) {
      final matchesQuery = job.title.toLowerCase().contains(query) ||
          job.company.toLowerCase().contains(query) ||
          job.location.toLowerCase().contains(query);

      final matchesCategory = category == 'All' ||
          (category == 'Software Eng' &&
              (job.title.contains('Engineer') ||
                  job.title.contains('Developer') ||
                  job.title.contains('Software') ||
                  job.title.contains('Backend') ||
                  job.title.contains('Frontend') ||
                  job.title.contains('Fullstack') ||
                  job.title.contains('iOS') ||
                  job.title.contains('Android') ||
                  job.title.contains('Kotlin') ||
                  job.title.contains('Flutter') ||
                  job.title.contains('Java') ||
                  job.title.contains('Python') ||
                  job.title.contains('Node') ||
                  job.title.contains('Go') ||
                  job.title.contains('Ruby') ||
                  job.title.contains('C++') ||
                  job.title.contains('PHP') ||
                  job.title.contains('TypeScript') ||
                  job.title.contains('JavaScript') ||
                  job.title.contains('Web') ||
                  job.title.contains('DevOps') ||
                  job.title.contains('Infrastructure') ||
                  job.title.contains('Security'))) ||
          (category == 'Data Science' &&
              (job.title.contains('Data') ||
                  job.title.contains('Analyst') ||
                  job.title.contains('AI') ||
                  job.title.contains('ML') ||
                  job.title.contains('Intelligence') ||
                  job.title.contains('Machine Learning') ||
                  job.title.contains('Analytics') ||
                  job.title.contains('Database') ||
                  job.title.contains('Scientist'))) ||
          (category == 'Design' &&
              (job.title.contains('Designer') ||
                  job.title.contains('Design') ||
                  job.title.contains('UX') ||
                  job.title.contains('UI') ||
                  job.title.contains('Product Designer') ||
                  job.title.contains('Graphic') ||
                  job.title.contains('Creative'))) ||
          (category == 'Operations' &&
              (job.title.contains('Manager') ||
                  job.title.contains('Management') ||
                  job.title.contains('Consultant') ||
                  job.title.contains('Lead') ||
                  job.title.contains('Director') ||
                  job.title.contains('Operations') ||
                  job.title.contains('HR') ||
                  job.title.contains('Sales') ||
                  job.title.contains('Recruiter') ||
                  job.title.contains('Marketing') ||
                  job.title.contains('Product Manager') ||
                  job.title.contains('Compliance') ||
                  job.title.contains('Support')));

      return matchesQuery && matchesCategory;
    }).toList();

    // Apply sorting
    if (selectedSortOption.value == 'Title (A-Z)') {
      filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (selectedSortOption.value == 'Title (Z-A)') {
      filtered.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
    } else if (selectedSortOption.value == 'Company (A-Z)') {
      filtered.sort((a, b) => a.company.toLowerCase().compareTo(b.company.toLowerCase()));
    } else if (selectedSortOption.value == 'Company (Z-A)') {
      filtered.sort((a, b) => b.company.toLowerCase().compareTo(a.company.toLowerCase()));
    } else {
      // Newest first (default)
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    filteredJobs.assignAll(filtered);
  }

  void toggleBookmark(JobModel job) {
    job.isBookmarked = !job.isBookmarked;
    allJobs.refresh();
    filteredJobs.refresh();
  }
}
