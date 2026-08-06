import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../utils/app_session.dart';
import '../auth_controller/auth_controller.dart';

class HomeController extends GetxController {
  var selectedIndex = 1.obs;
  var isLoggedIn = false.obs;
  var showSplash = false.obs;

  final List<String> webSeriesImages = [
    "assets/images/taskaree.jpg",
    "assets/images/sahid_teri_bato.jpg",
    "assets/images/farzi.jpg",
    "assets/images/khaki.webp",
    "assets/images/kota_factory.jpg",
    "assets/images/asur.webp",
    "assets/images/asur2.jpeg",
  ];

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  void checkLoginStatus() async {
    isLoggedIn.value = AppSession.getLogin();
  }

  void onItemTapped(int index) {
    selectedIndex.value = index;
    if (index == 2) {
      if (Get.currentRoute != AppRoutes.profile) {
        Get.toNamed(AppRoutes.profile);
      }
    } else if (index == 1) {
      if (Get.currentRoute != AppRoutes.home && Get.currentRoute != AppRoutes.navbar) {
        Get.toNamed(AppRoutes.home);
      }
    } else if (index == 0) {
      if (Get.currentRoute != AppRoutes.upcoming) {
        Get.toNamed(AppRoutes.upcoming);
      }
    }
  }

  void logout() async {
    final authController = Get.find<AuthController>();
    await authController.logout();
    isLoggedIn.value = false;
    selectedIndex.value = 1;
  }
}
