import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/responsive.dart';
import '../../view_model/primium_controller/premium_controller.dart';
import '../../app/theme/app_colors.dart';
import '../../view_model/home_controller/home_controller.dart';
import '../../widgets/expendable_plan_card.dart';
import '../../widgets/golden_button.dart';
import '../../widgets/golden_text.dart';
import '../auth/signInPage.dart';
import '../popUp/promo_code_popup.dart';
import '../popUp/redeem_voucher_page.dart';
import '../../utils/custom_snackbar.dart';

class GoPremiumPage extends StatelessWidget {
  const GoPremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final PremiumController controller = Get.put(PremiumController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Responsive.backButton(context, onPressed: () => Get.back()),
        title: const GoldenText(
          "Premium Plans",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        return SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      /// 🔹 Header Section with Icon
                      const SizedBox(height: 20),
                      const Icon(Icons.stars, color: AppColors.goldBase, size: 60),
                      const SizedBox(height: 10),
                      const GoldenText(
                        "Unlock Premium Content",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "Choose a plan that works for you",
                        style: TextStyle(color: AppColors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 30),

                      /// 🔹 Common Features
                      _buildFeaturesList(),

                      const SizedBox(height: 30),

                      /// 🔹 Plans List
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Obx(() {
                          if (controller.plans.isEmpty) {
                            return const Center(
                              child: GoldenText("No plans available", 
                              style: TextStyle(fontSize: 16)));
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: controller.plans.length,
                            itemBuilder: (context, index) {
                              final plan = controller.plans[index];
                              return Obx(() => ExpandablePlanCard(
                                title: plan.name,
                                price: "₹${plan.price}",
                                duration: "/ ${plan.duration} Days",
                                features: plan.features,
                                isHighlighted: controller.selectedPlanIndex.value == index,
                                onSelect: () => controller.selectPlan(index),
                                onBuy: () {
                                  controller.selectPlan(index);
                                  if (!controller.isUserLoggedIn.value) {
                                    Get.to(() => const SignInPage(), arguments: {"returnRoute": Get.currentRoute});
                                  } else if (controller.hasActiveSubscription) {
                                    CustomSnackbar.show(title: "Info", message: "Already Purchased");
                                  } else {
                                    controller.subscribeToPlan(plan.id!);
                                  }
                                },
                              ));
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              /// 🔹 Bottom Actions
              _buildBottomActions(controller),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFeaturesList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _featureRow(Icons.hd_outlined, "High Quality Videos"),
          _featureRow(Icons.ad_units_outlined, "Ad Free Experience"),
          _featureRow(Icons.download_for_offline_outlined, "Affordable Packs"),
          _featureRow(Icons.devices_other, "New Releases"),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.goldBase, size: 22),
          const SizedBox(width: 15),
          GoldenText(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBottomActions(PremiumController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                if (controller.isUserLoggedIn.value) {
                  Get.dialog(const ApplyPromoPopup());
                } else {
                  _showSignInPopup();
                }
              },
              icon: const Icon(Icons.local_offer_outlined, color: AppColors.primary),
              label: const GoldenText("Promo Code", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          Container(height: 30, width: 1, color: Colors.white10),
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                if (controller.isUserLoggedIn.value) {
                  Get.to(() => RedeemVoucherPage());
                } else {
                  _showSignInPopup();
                }
              },
              icon: const Icon(Icons.confirmation_num_outlined, color: AppColors.primary),
              label: const GoldenText("Redeem Code", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignInPopup() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const GoldenText("Sign In Required", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          "Please sign in to complete the payment.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          GoldenButton(
            width: 120,
            height: 40,
            onPressed: () {
              Get.back();
              Get.to(() => const SignInPage(), arguments: {"returnRoute": Get.currentRoute});
            },
            child: const Text("Sign In", style: TextStyle(color: AppColors.buttonTextColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
