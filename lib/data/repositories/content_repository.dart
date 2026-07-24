import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nazar_ott/data/models/catagory_model/catagory_model.dart';

import '../models/response_model/content_response_model/content_model.dart';
import '../network/base_api_service.dart';
import '../../utils/constants.dart';

class ContentRepository {
  final BaseApiService apiProvider;

  ContentRepository(this.apiProvider);

  Future<List<ContentModel>> getAllContent() async {
    try {
      final response = await apiProvider.getApi(AppConstants.getAllContent);
      if (response['success'] == true) {
        // The API returns the list under the 'content' key
        List<dynamic> data = response['content'] ?? [];
        return data.map((item) => ContentModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching content: $e");
      rethrow;
    }
  }

  Future<ContentModel?> getContentById(String contentId) async {
    try {
      final response = await apiProvider.getApi(AppConstants.getContentById(contentId));
      if (response['success'] == true) {
        return ContentModel.fromJson(response['content']);
      }
      return null;
    } catch (e) {
      print("Error fetching content by ID: $e");
      rethrow;
    }
  }

  Future<List<ContentModel>> getEpisodes(String seriesId) async {
    try {
      final response = await apiProvider.getApi(
        AppConstants.getEpisodes(seriesId),
      );
      if (response['success'] == true) {
        List<dynamic> data = response['episodes'] ?? [];
        return data.map((item) => ContentModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching episodes: $e");
      rethrow;
    }
  }

  Future<List<CategoryModel>> allCategory() async {
    try {
      final url = Uri.parse(AppConstants.categoryUrl);

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        final CategoryResponse categoryResponse = CategoryResponse.fromJson(
          data,
        );

        return categoryResponse.categories;
      } else {
        throw Exception(
          'Failed to load categories. Status Code: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Category API Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
