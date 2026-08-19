import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nazar_ott/app/routes/app_routes.dart';
import 'package:nazar_ott/app/theme/app_colors.dart';
import 'package:nazar_ott/utils/facebook_meta_events.dart';
import 'package:nazar_ott/utils/firebase_analytics_event.dart';

class PaymentSuccessPage extends StatefulWidget {
  const PaymentSuccessPage({super.key});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  final Map<String, dynamic> arguments = Get.arguments ?? {};

  @override
  void initState() {
    super.initState();
    _triggerEvents();
  }

  void _triggerEvents() {
    final double amount = arguments['amount'] ?? 0.0;
    final String planId = arguments['planId'] ?? 'unknown';

    // Trigger Meta (Facebook) Purchase Event
    FacebookEventsService.logPurchase(
      amount: amount,
      currency: "INR",
      contentId: planId,
    );

    // Trigger Firebase Purchase Event
    FirebaseAnalyticsService.logPurchase(
      amount: amount,
      currency: "INR",
      contentId: planId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                "Congratulations!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Your subscription to ${arguments['planName'] ?? 'Premium'} is now active.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Get.offAllNamed(AppRoutes.home),
                  child: const Text(
                    "Start Watching",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
