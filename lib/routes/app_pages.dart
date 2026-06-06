import 'package:get/get.dart';
import '../controllers/job_controller.dart';
import '../views/dashboard/job_dashboard_view.dart';
import '../views/detail/job_detail_view.dart';
import '../views/splash/splash_view.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const JobDashboardView(),
      binding: BindingsBuilder(() {
        Get.put(JobController());
      }),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),
    GetPage(
      name: AppRoutes.detail,
      page: () => const JobDetailView(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}
