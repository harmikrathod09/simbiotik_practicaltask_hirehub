import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/job_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/job_model.dart';

class JobDetailView extends StatefulWidget {
  const JobDetailView({super.key});

  @override
  State<JobDetailView> createState() => _JobDetailViewState();
}

class _JobDetailViewState extends State<JobDetailView> {
  final JobController controller = Get.find<JobController>();
  late JobModel job;
  late bool isBookmarked;
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    job = Get.arguments as JobModel;
    isBookmarked = job.isBookmarked;
  }

  void _toggleBookmark() {
    setState(() {
      isBookmarked = !isBookmarked;
    });
    controller.toggleBookmark(job);

    Get.snackbar(
      isBookmarked ? 'Bookmark Saved' : 'Bookmark Removed',
      isBookmarked
          ? 'Added ${job.title} to your bookmarked positions.'
          : 'Removed ${job.title} from bookmarks.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.primary,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      borderColor: AppColors.border,
      borderWidth: 1.0,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _launchApplyUrl() async {
    final rawUrl = job.url;
    debugPrint('Launching Job URL: $rawUrl');
    if (rawUrl.isEmpty) {
      _showUrlError('No application URL is available for this job.');
      return;
    }

    setState(() => _isLaunching = true);

    try {
      final uri = Uri.parse(rawUrl);
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      // Fallback to platform default mode if external browser launch fails
      if (!launched) {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }

      if (!launched) {
        _showUrlError('Could not open the application page. Please try again.');
      }
    } catch (e) {
      debugPrint('Launch URL error: $e');
      _showUrlError('Invalid application URL. Please try again later.');
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  void _showUrlError(String message) {
    Get.snackbar(
      'Unable to Open',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.error.withValues(alpha: 0.1),
      colorText: AppColors.error,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      borderColor: AppColors.error.withValues(alpha: 0.3),
      borderWidth: 1.0,
      icon: const Icon(Icons.error_outline, color: AppColors.error),
      duration: const Duration(seconds: 3),
    );
  }

  Widget _buildDetailBadge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUrl = job.url.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Job Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.favorite : Icons.favorite_border,
              color: isBookmarked ? Colors.red : AppColors.primary,
              size: 22,
            ),
            onPressed: _toggleBookmark,
          ),
        ],
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      // ── Clean bottom bar: no Stack overlap ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: hasUrl ? AppColors.accent : AppColors.border,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              disabledBackgroundColor: AppColors.border,
              disabledForegroundColor: AppColors.secondary,
            ),
            onPressed: hasUrl && !_isLaunching ? _launchApplyUrl : null,
            child: _isLaunching
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.open_in_new_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        hasUrl ? 'Apply Now' : 'No Application URL',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),

      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // 1. Job Title
                  Text(
                    job.title,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 2. Company Name
                  Text(
                    job.company,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Location row
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 15, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          job.location,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.secondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 4. Info badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDetailBadge(context, job.timeType),
                      _buildDetailBadge(context, job.experienceLevel),
                      _buildDetailBadge(context, job.salary),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 4.5. Tags (if present)
                  if (job.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: job.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.12),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 22),

                  // 5. Description
                  _sectionHeader(theme, 'Job Description'),
                  const SizedBox(height: 10),
                  Text(
                    job.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: AppColors.primary.withValues(alpha: 0.88),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 6. Requirements (if any)
                  if (job.requirements.isNotEmpty) ...[
                    _sectionHeader(theme, 'Requirements'),
                    const SizedBox(height: 10),
                    ...job.requirements.map((req) => _bulletItem(theme, req, Icons.circle)),
                    const SizedBox(height: 16),
                  ],
                  // 7. Benefits (if any)
                  if (job.benefits.isNotEmpty) ...[
                    _sectionHeader(theme, 'Benefits'),
                    const SizedBox(height: 10),
                    ...job.benefits.map((ben) => _bulletItem(theme, ben, Icons.circle)),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
        fontSize: 17,
      ),
    );
  }

  Widget _bulletItem(ThemeData theme, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3.0),
            child: Icon(icon, size: 10, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
