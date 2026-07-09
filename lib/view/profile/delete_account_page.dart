import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../utils/responsive.dart';
import '../../widgets/golden_button.dart';
import '../../widgets/golden_text.dart';
import '../../utils/custom_snackbar.dart';
import '../../view_model/auth_controller/auth_controller.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedReason;
  final List<String> _reasons = [
    "I'm not using the app anymore",
    "Subscription is too expensive",
    "Content quality is not as expected",
    "Technical issues/App bugs",
    "Privacy concerns",
    "Found a better alternative",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    // Auto-fetch user details
    final userData = authController.userData.value;
    if (userData != null) {
      _nameController.text = userData['name'] ?? '';
      _contactController.text = userData['email'] ?? userData['phone'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedReason == null) {
        CustomSnackbar.show(title: "Error", message: "Please select a reason", isError: true);
        return;
      }

      Get.dialog(
        AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const GoldenText("Confirm Deletion", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          content: const Text(
            "Your account will be deleted in 24 to 48 hours. Do you want to delete your account permanently?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("Cancel", style: TextStyle(color: Colors.white)),
            ),
            GoldenButton(
              width: 100,
              height: 40,
              onPressed: () {
                Get.back();
                
                // Clear fields
                _reasonController.clear();
                setState(() {
                  _selectedReason = null;
                });

                CustomSnackbar.show(
                  title: "Success",
                  message: "Your account deletion request has been scheduled. It will be deleted within 48 hours.",
                  isSuccess: true,
                );
                
                // Navigate back after short delay
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) Get.back();
                });
              },
              child: const Text("Delete", style: TextStyle(color: AppColors.buttonTextColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Responsive.backButton(context, onPressed: () => Get.back()),
        title: const GoldenText(
          "Delete Account",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 600 : double.infinity),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 60),
                  const SizedBox(height: 20),
                  const GoldenText(
                    "We're sorry to see you go",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Please fill out the form below to request account deletion. Once processed, all your data, including watch history and subscriptions, will be permanently removed.",
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 40),
                  
                  _buildLabel("Full Name"),
                  _buildTextField(
                    controller: _nameController,
                    hint: "Enter your full name",
                    readOnly: true, // Auto-fetched
                    validator: (value) => value!.isEmpty ? "Please enter your name" : null,
                  ),
                  
                  const SizedBox(height: 20),
                  _buildLabel("Email or Phone Number"),
                  _buildTextField(
                    controller: _contactController,
                    hint: "Enter email or phone number",
                    readOnly: true, // Auto-fetched
                    validator: (value) => value!.isEmpty ? "Please enter contact info" : null,
                  ),
                  
                  const SizedBox(height: 20),
                  _buildLabel("Reason for Deletion"),
                  _buildDropdown(),
                  
                  if (_selectedReason == "Other") ...[
                    const SizedBox(height: 20),
                    _buildLabel("Specify Reason"),
                    _buildTextField(
                      controller: _reasonController,
                      hint: "Please tell us why you want to leave",
                      maxLines: 4,
                      validator: (value) => value!.isEmpty ? "Please provide a reason" : null,
                    ),
                  ],
                  
                  const SizedBox(height: 50),
                  SizedBox(
                    width: double.infinity,
                    child: GoldenButton(
                      onPressed: _handleSubmit,
                      height: 55,
                      borderRadius: BorderRadius.circular(10),
                      child: const Text(
                        "SUBMIT REQUEST",
                        style: TextStyle(
                          color: AppColors.buttonTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedReason,
          hint: const Text("Select a reason", style: TextStyle(color: Colors.white30, fontSize: 14)),
          dropdownColor: Colors.grey[900],
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: _reasons.map((String reason) {
            return DropdownMenuItem<String>(
              value: reason,
              child: Text(reason),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedReason = newValue;
              if (newValue != "Other") {
                _reasonController.clear();
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      style: TextStyle(color: readOnly ? Colors.white54 : Colors.white),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
        filled: true,
        fillColor: readOnly ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
