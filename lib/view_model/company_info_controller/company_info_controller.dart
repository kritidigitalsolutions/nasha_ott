// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:nazar_ott/data/models/response_model/address_response.dart';
import 'package:nazar_ott/data/models/response_model/help_model.dart';
import 'package:nazar_ott/data/repositories/company_repository.dart';

class CompanyController extends GetxController {
  final CompanyRepository _repository = CompanyRepository();

  final Rx<AddressResponse?> companyInfo = Rx<AddressResponse?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  RxBool isLoadingHelp = false.obs;
  Rxn<HelpResponse> helpResponse = Rxn<HelpResponse>();
  RxList<HelpModel> helpList = <HelpModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCompanyInfo();
    getAllHelp();
  }

  Future<void> fetchCompanyInfo() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _repository.getCompanyInfo();

      if (response != null) {
        companyInfo.value = response;
      } else {
        errorMessage.value = 'Failed to load company info';
      }
    } catch (e) {
      errorMessage.value = 'Something went wrong: $e';
      print("❌ Error in fetchCompanyInfo: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Get Help Data
  Future<void> getAllHelp() async {
    try {
      isLoadingHelp.value = true;

      final response = await _repository.allHelp();

      if (response != null) {
        print("Help Response: ${response.toJson()}");
        helpResponse.value = response;
        helpList.assignAll(response.helpData);
      }
    } catch (e) {
      print("Help Error: $e");
    } finally {
      isLoadingHelp.value = false;
    }
  }
}
