import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nazar_ott/data/models/response_model/address_response.dart';
import 'package:nazar_ott/data/models/response_model/help_model.dart';
import 'package:nazar_ott/utils/constants.dart';

class CompanyRepository {
  Future<AddressResponse?> getCompanyInfo() async {
    try {
      final url = Uri.parse(AppConstants.companyUrl);

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print(jsonDecode(response.body));
        return AddressResponse.fromJson(jsonDecode(response.body));
      } else {
        print("Request failed: ${response.statusCode}");
        print(response.body);
        return null;
      }
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  Future<HelpResponse?> allHelp() async {
    try {
      final url = Uri.parse(AppConstants.helpApi);

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print(jsonDecode(response.body));
        return HelpResponse.fromJson(jsonDecode(response.body));
      } else {
        print('Request Failed: ${response.statusCode}');
        print(response.body);
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}
