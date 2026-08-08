import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../utils/app_images.dart';
import '../../utils/responsive.dart';
import '../../widgets/custom_network_image.dart';
import '../../widgets/golden_button.dart';
import '../../widgets/golden_text.dart';
import '../../widgets/google_web_sign_in_button.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../view_model/auth_controller/auth_controller.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthController authController = Get.find<AuthController>();

  final isAgeConfirmed = false.obs;
  final showCodeField = false.obs;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  String? returnRoute;
  String? contentId; // NEW: carries the drama-details content id forward

  @override
  void initState() {
    super.initState();
    // Capture return route and content id from arguments if provided
    returnRoute = Get.arguments is Map ? Get.arguments['returnRoute'] : null;
    contentId = Get.arguments is Map ? Get.arguments['id'] : null; // NEW
  }

  void _handleLoginSuccess() {
    if (returnRoute != null && returnRoute!.isNotEmpty) {
      Get.offAllNamed(returnRoute!);
    } else if (Get.previousRoute.isNotEmpty &&
        Get.previousRoute != AppRoutes.splash &&
        Get.previousRoute != AppRoutes.signIn) {
      Get.back();
    } else {
      Get.offAllNamed(AppRoutes.navbar);
    }
  }

  /// ✅ NEW: Central place to decide what happens right after a successful
  /// Google sign-in response comes back.
  ///
  /// - New user (first time Google sign-in)  -> show bottom sheet asking for
  ///   a phone number. User can fill it in, or skip (in which case a dummy
  ///   numeric phone is generated & saved automatically).
  /// - Existing user -> do NOT show any bottom sheet. Just silently make sure
  ///   the stored phone is valid; if it's missing/invalid, fix it in the
  ///   background without blocking navigation. Then navigate as usual.
  Future<void> _handlePostGoogleLogin(dynamic response) async {
    final bool isNew = response.isNewUser == true;

    if (isNew) {
      _showPhoneNumberBottomSheet();
    } else {
      if (authController.isPhoneMissing(response.user)) {
        await authController.generateAndSaveDummyPhone();
      }
      _handleLoginSuccess();
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: Responsive.backButton(
            context,
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Get.back();
            },
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.05,
                      ),
                      Image.asset(AppImages.logo, height: 100),
                      const SizedBox(height: 25),
                      const GoldenText(
                        "Welcome",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Column(
                        children: [
                          Column(
                            children: [
                              TextFormField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(color: Colors.white),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Phone is required";
                                  }
                                  if (value.length != 10) {
                                    return "Phone number must be 10 digits";
                                  }
                                  if (!RegExp(r'^[6789]').hasMatch(value)) {
                                    return "Number must start with 6, 7, 8, or 9";
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  prefixText: "+91 ",
                                  prefixStyle: const TextStyle(
                                    color: Colors.white,
                                  ),
                                  hintText: "Phone Number",
                                  hintStyle: const TextStyle(
                                    color: Colors.white54,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[900],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              /// AGE CHECKBOX
                              // const SizedBox(height: 20),

                              /// GET OTP BUTTON
                              _buildGetOtpButton(),
                            ],
                          ),
                          const SizedBox(height: 25),
                          const Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white24)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: GoldenText(
                                  "OR",
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.white24)),
                            ],
                          ),
                          const SizedBox(height: 25),

                          /// LOGIN WITH GOOGLE
                          if (kIsWeb)
                            GoogleWebSignInButton(
                              googleSignIn: authController.googleSignIn,
                              onSignedIn: (googleUser) async {
                                final response = await authController
                                    .signInWithGoogle(googleUser);
                                if (response != null) {
                                  await _handlePostGoogleLogin(response);
                                }
                              },
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: Obx(
                                () => GoldenButton(
                                  onPressed:
                                      authController.isGoogleLoading.value
                                      ? null
                                      : () async {
                                          final response = await authController
                                              .signInWithGoogle();
                                          if (response != null) {
                                            await _handlePostGoogleLogin(
                                              response,
                                            );
                                          }
                                        },
                                  child: authController.isGoogleLoading.value
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            CustomNetworkImage(
                                              imageUrl:
                                                  'https://auth.services.adobe.com/img/google_logo.svg',
                                              height: 24,
                                              errorWidget: const Icon(
                                                Icons.g_mobiledata,
                                                color: Colors.white,
                                                size: 30,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const FittedBox(
                                              child: Text(
                                                "Continue with Google",
                                                style: TextStyle(
                                                  color:
                                                      AppColors.buttonTextColor,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // void _showEmailPicker() {
  //   final TextEditingController emailPicker = TextEditingController();
  //   Get.bottomSheet(
  //     Container(
  //       padding: const EdgeInsets.all(20),
  //       decoration: const BoxDecoration(
  //         color: Colors.black,
  //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //         border: Border(top: BorderSide(color: Colors.white12)),
  //       ),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           const Text(
  //             "Login with Email",
  //             style: TextStyle(
  //               color: Colors.white,
  //               fontSize: 18,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //           const SizedBox(height: 20),
  //           AutofillGroup(
  //             child: TextFormField(
  //               controller: emailPicker,
  //               autofocus: true,
  //               autofillHints: const [AutofillHints.email],
  //               keyboardType: TextInputType.emailAddress,
  //               style: const TextStyle(color: Colors.white),
  //               decoration: InputDecoration(
  //                 hintText: "Select or type email",
  //                 hintStyle: const TextStyle(color: Colors.white54),
  //                 filled: true,
  //                 fillColor: Colors.grey[900],
  //                 border: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(12),
  //                   borderSide: BorderSide.none,
  //                 ),
  //               ),
  //             ),
  //           ),
  //           const SizedBox(height: 20),
  //           GoldenButton(
  //             height: 50,
  //             onPressed: () async {
  //               if (emailPicker.text.contains('@')) {
  //                 String email = emailPicker.text.trim();
  //                 Get.back();
  //                 await Future.delayed(const Duration(milliseconds: 250));
  //                 bool success = await authController.sendOtp(email);
  //                 if (success) {
  //                   Get.toNamed(
  //                     AppRoutes.otpPage,
  //                     arguments: {'phoneNumber': email, ...?Get.arguments},
  //                   );
  //                 }
  //               } else {
  //                 Get.snackbar(
  //                   "Error",
  //                   "Please enter a valid email",
  //                   snackPosition: SnackPosition.BOTTOM,
  //                   backgroundColor: Colors.red,
  //                   colorText: Colors.white,
  //                 );
  //               }
  //             },
  //             child: const Text(
  //               "Continue",
  //               style: TextStyle(color: Colors.white),
  //             ),
  //           ),
  //           const SizedBox(height: 10),
  //         ],
  //       ),
  //     ),
  //     isScrollControlled: true,
  //   );
  // }

  void _showPhoneNumberBottomSheet() {
    final TextEditingController phoneSheetController = TextEditingController();
    final GlobalKey<FormState> sheetFormKey = GlobalKey<FormState>();
    final RxBool isSaving = false.obs;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        child: Form(
          key: sheetFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add your mobile number",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "This helps us keep your account secure. You can skip this for now.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: phoneSheetController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null; // optional field, skip allowed
                  }
                  if (value.length != 10) {
                    return "Phone number must be 10 digits";
                  }
                  if (!RegExp(r'^[6789]').hasMatch(value)) {
                    return "Number must start with 6, 7, 8, or 9";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  prefixText: "+91 ",
                  prefixStyle: const TextStyle(color: Colors.white),
                  hintText: "Phone Number",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: GoldenButton(
                    onPressed: isSaving.value
                        ? null
                        : () async {
                            if (!sheetFormKey.currentState!.validate()) {
                              return;
                            }

                            isSaving.value = true;
                            final entered = phoneSheetController.text.trim();

                            bool ok;
                            if (entered.isEmpty) {
                              // ✅ User didn't fill a number -> generate dummy
                              ok = await authController
                                  .generateAndSaveDummyPhone();
                            } else {
                              // ✅ User filled a number -> save it as-is
                              ok = await authController.updatePhoneNumber(
                                entered,
                              );
                            }

                            isSaving.value = false;
                            if (ok) {
                              Get.back(); // close bottom sheet
                              _handleLoginSuccess();
                            }
                          },
                    child: isSaving.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Save & Continue",
                            style: TextStyle(color: AppColors.buttonTextColor),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Obx(
                () => TextButton(
                  onPressed: isSaving.value
                      ? null
                      : () async {
                          isSaving.value = true;
                          await authController.generateAndSaveDummyPhone();
                          isSaving.value = false;
                          Get.back();
                          _handleLoginSuccess();
                        },
                  child: const Text(
                    "Skip for now",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
    );
  }

  Widget _buildGetOtpButton() {
    return Obx(
      () => GoldenButton(
        onPressed: (!authController.isLoading.value)
            ? () async {
                if (_formKey.currentState!.validate()) {
                  String valueToSend = "+91${phoneController.text.trim()}";
                  bool success = await authController.sendOtp(valueToSend);
                  if (success) {
                    Get.toNamed(
                      AppRoutes.otpPage,
                      arguments: {
                        'phoneNumber': valueToSend,
                        ...?Get.arguments,
                      },
                    );
                  }
                }
              }
            : null,
        child: authController.isLoading.value
            ? const CircularProgressIndicator(color: AppColors.buttonTextColor)
            : const FittedBox(
                child: Text(
                  "Get OTP",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.buttonTextColor,
                  ),
                ),
              ),
      ),
    );
  }
}
