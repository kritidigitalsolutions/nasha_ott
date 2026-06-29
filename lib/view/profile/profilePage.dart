import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../utils/responsive.dart';
import 'privacy_policy_page.dart';
import 'setting_page.dart';
import '../../view_model/primium_controller/premium_controller.dart';
import '../../utils/constants.dart';
import '../../view_model/home_controller/home_controller.dart';
import '../../widgets/custom_network_image.dart';
import '../../widgets/golden_text.dart';
import '../../widgets/golden_button.dart';
import '../../app/theme/app_colors.dart';
import '../../view_model/auth_controller/auth_controller.dart';
import '../auth/signInPage.dart';
import 'watchlist.dart';
import '../navbar/downloads.dart';
import '../premium/goPremium.dart';
import 'purchased_plans_page.dart';
import 'Rate_your_app.dart';
import 'help_page.dart';
import 'refund_policy_page.dart';
import 'terms_condition_page.dart';

class ProfilePage extends StatelessWidget {
  final VoidCallback onLogout;

  const ProfilePage({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final PremiumController premiumController = Get.put(PremiumController());
    final HomeController homeController = Get.find<HomeController>();
    bool isDesktop = Responsive.isDesktop(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authController.userData.value == null) {
        authController.getProfile();
      }
      if (authController.isLoggedIn.value && premiumController.subscriptionData.value == null) {
        premiumController.fetchSubscriptionStatus();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop ? null : AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Responsive.backButton(context, onPressed: () {
          homeController.selectedIndex.value = 1; 
        }),
        title: const GoldenText("Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (!isDesktop) const SizedBox(height: 20),
                if (isDesktop) const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Obx(() {
                            final bool isLoggedIn = authController.isLoggedIn.value;
                            final user = authController.userData.value;

                            if (!isLoggedIn) {
                              return Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 25,
                                    backgroundColor: AppColors.grey,
                                    child: Icon(Icons.person, color: AppColors.white, size: 30),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        GoldenText(
                                          "Welcome Guest",
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          "Sign in to access all features",
                                          style: TextStyle(color: AppColors.grey, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GoldenButton(
                                    width: 100,
                                    height: 35,
                                    onPressed: () => Get.toNamed(AppRoutes.signIn, arguments: {"returnRoute": Get.currentRoute}),
                                    borderRadius: BorderRadius.circular(8),
                                    child: const FittedBox(child: Text("SIGN IN", style: TextStyle(color: AppColors.buttonTextColor, fontSize: 12, fontWeight: FontWeight.bold))),
                                  ),
                                ],
                              );
                            }

                            String? imageUrl = user?['avatar'] ?? user?['image'] ?? user?['profileImage'];
                            if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                              imageUrl = "${AppConstants.serverUrl}/$imageUrl";
                            }

                            return Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.grey[800],
                                  child: (imageUrl != null && imageUrl.isNotEmpty)
                                      ? CustomNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          width: 50,
                                          height: 50,
                                          borderRadius: 25,
                                          placeholder: const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.buttonColor),
                                            ),
                                          ),
                                          errorWidget: const Icon(Icons.person, color: AppColors.white, size: 30),
                                        )
                                      : const Icon(Icons.person, color: AppColors.white, size: 30),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      GoldenText(
                                        user?['name'] ?? "User Name",
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (user?['email'] != null && user!['email'].toString().isNotEmpty)
                                            ? user['email']
                                            : (user?['phone'] ?? "No Contact Info"),
                                        style: const TextStyle(color: AppColors.grey, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),

                        const Divider(color: Colors.grey, height: 1),

                        Obx(() {
                          final sub = premiumController.subscriptionData.value;
                          final bool hasActiveSub = sub != null && sub['status'] == 'active';

                          return InkWell(
                            onTap: () {
                              if (hasActiveSub) {
                                Get.toNamed(AppRoutes.purchasedPlans);
                              } else {
                                Get.toNamed(AppRoutes.goPremium);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "My Plan",
                                        style: TextStyle(color: AppColors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                      GoldenText(
                                        hasActiveSub ? (sub['plan']?['name'] ?? "Active Plan") : "No Active Plans",
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  if (!hasActiveSub)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.buttonGradient,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text("SUBSCRIBE", style: TextStyle(color: AppColors.buttonTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                    )
                                  else
                                    const Icon(Icons.verified, color: Colors.green, size: 24),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                buildMenuItem(context, Icons.bookmark_border, "Watchlist", AppRoutes.watchList),
                if (!kIsWeb) buildMenuItem(context, Icons.download_for_offline_outlined, "Downloads", AppRoutes.downloads),
                buildMenuItem(context, Icons.settings_outlined, "Settings", AppRoutes.setting),
                buildMenuItem(context, Icons.rate_review, "Rate Our App", AppRoutes.rateApp),
                buildMenuItem(context, Icons.info_outline, "Terms & Conditions", AppRoutes.termsAndConditions),
                buildMenuItem(context, Icons.privacy_tip, "Privacy Policy", AppRoutes.privacyPolicy),
                buildMenuItem(context, Icons.currency_rupee, "Refund Policy", AppRoutes.refundPolicy),
                // buildMenuItem(context, Icons.help_outline, "Help", AppRoutes.helpSupport),

                const SizedBox(height: 20),
                Center(
                  child: Obx(() => GoldenButton(
                    width: 180,
                    height: 45,
                    borderRadius: BorderRadius.circular(25),
                    onPressed: authController.isLoggedIn.value 
                        ? onLogout 
                        : () => Get.toNamed(AppRoutes.signIn, arguments: {"returnRoute": Get.currentRoute}),
                    child: Text(
                        authController.isLoggedIn.value ? "SIGN OUT" : "SIGN IN", 
                        style: const TextStyle(color: AppColors.buttonTextColor, fontWeight: FontWeight.bold)),
                  )),
                ),
                const SizedBox(height: 30),
                const Text("App Version 1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildMenuItem(BuildContext context, IconData icon, String title, String route) {
    return InkWell(
      onTap: () => Get.toNamed(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.goldBase, size: 22),
            const SizedBox(width: 15),
            Text(title, style: const TextStyle(color: AppColors.white, fontSize: 16)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
          ],
        ),
      ),
    );
  }
}
