// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:nazar_ott/data/models/catagory_model/catagory_model.dart';
import '../../data/models/response_model/content_response_model/content_model.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/interaction_repository.dart';
import '../../data/network/api_network_service.dart';

/// Simple model to hold a category section with its content and priority,
/// so the UI can render sections in guaranteed priority order.
class CategorySection {
  // final String name;
  final String title;
  final int priority;
  final String categorySlug;
  final List<ContentModel> content;

  CategorySection({
    // required.th
    required this.title,
    required this.priority,
    required this.categorySlug,
    required this.content,
  });
}

class ContentController extends GetxController {
  final ContentRepository _repository = ContentRepository(NetworkApiService());
  final InteractionRepository _interactionRepo = InteractionRepository(
    NetworkApiService(),
  );
  var contentDetail = Rxn<ContentModel>();
  var isContentDetailLoading = false.obs;
  var isLoading = true.obs;
  var isCategoryLoading = true.obs;

  var allContent = <ContentModel>[].obs;
  var allCategory = <CategoryModel>[].obs;

  var allWebBannerContent = <ContentModel>[].obs;
  var homeBannerContent = <ContentModel>[].obs; // Added for slider
  var webSections = <WebSectionModel>[].obs;

  var trendingContent = <ContentModel>[].obs;
  var seriesEpisodes = <ContentModel>[].obs;
  var isEpisodesLoading = false.obs;

  // Ordered list of category sections (lowest priority number = shown first/above)
  var categorySections = <CategorySection>[].obs;

  // Cache for likes: ContentID -> LikeCount
  var contentLikes = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  Future<void> _initData() async {
    if (kIsWeb) {
      isCategoryLoading.value = false;
      fetchContent();
    } else {
      isLoading.value = false;
      // Fetch categories first for progressive loading
      fetchCategory();
    }
  }

  Future<void> fetchContent() async {
    try {
      isLoading.value = true;
      // -----------------------------
      // web banner content
      //-------------------------------------------------

      final webBannerContent = await _repository.getAllWebSiteBannerContent();
      // Sort web banners only by position
      webBannerContent.sort((a, b) {
        int posA = a.position ?? 999;
        int posB = b.position ?? 999;
        return posA.compareTo(posB);
      });
      allWebBannerContent.assignAll(webBannerContent);

      // Also add banners to allContent
      for (var item in webBannerContent) {
        if (!allContent.any((existing) => existing.id == item.id)) {
          allContent.add(item);
        }
      }

      final sections = await _repository.getWebSections();
      // Sort items in web sections only by position
      for (var section in sections) {
        section.items.sort((a, b) {
          int posA = a.position ?? 999;
          int posB = b.position ?? 999;
          return posA.compareTo(posB);
        });

        // Add section items to allContent
        for (var item in section.items) {
          if (!allContent.any((existing) => existing.id == item.id)) {
            allContent.add(item);
          }
        }
      }
      webSections.assignAll(sections);
    } catch (e) {
      print("Error in ContentController fetchContent: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCategory() async {
    try {
      isCategoryLoading.value = true;
      final categories = await _repository.allCategory();

      // Sort categories only by position (1 is top)
      categories.sort((a, b) {
        int posA = a.position ?? 999;
        int posB = b.position ?? 999;
        return posA.compareTo(posB);
      });
      allCategory.assignAll(categories);

      // Clear existing data
      categorySections.clear();
      homeBannerContent.clear();

      // Fetch all category content in parallel and AWAIT all of them
      await Future.wait(categories.map((cat) => _fetchContentForCategory(cat)));

      // Final sort of sections by category position to ensure correct order after parallel fetch
      categorySections.sort((a, b) {
        int posA = a.priority ?? 999;
        int posB = b.priority ?? 999;
        return posA.compareTo(posB);
      });
    } catch (e) {
      print("Error fetching categories: $e");
    } finally {
      isCategoryLoading.value = false;
    }
  }

  Future<void> _fetchContentForCategory(CategoryModel cat) async {
    try {
      final contentList = await _repository.getCategoryContent(cat.id);

      // Filter by isPublished: true and isHide: false
      final filteredContent =
          contentList.where((c) {
            return c.isPublished == true && c.isHide == false;
          }).toList();

      // Strict sorting by position only (ascending)
      filteredContent.sort((a, b) {
        int posA = a.position ?? 999;
        int posB = b.position ?? 999;
        return posA.compareTo(posB);
      });

      if (cat.slug == 'home-banners') {
        homeBannerContent.assignAll(filteredContent);
      } else if (filteredContent.isNotEmpty) {
        // Only add section if it has content
        categorySections.add(
          CategorySection(
            title: cat.name,
            priority: cat.priority,
            categorySlug: cat.slug,
            content: filteredContent,
          ),
        );
      }

      // Populate allContent for "More Like This" feature
      for (var item in filteredContent) {
        if (!allContent.any((existing) => existing.id == item.id)) {
          allContent.add(item);
        }
      }
    } catch (e) {
      print("Error fetching content for category ${cat.name}: $e");
    }
  }

  Future<void> fetchEpisodes(String seriesId) async {
    try {
      isEpisodesLoading.value = true;
      seriesEpisodes.clear();
      final episodes = await _repository.getEpisodes(seriesId);
      seriesEpisodes.assignAll(episodes);
    } catch (e) {
      print("Error fetching episodes: $e");
    } finally {
      isEpisodesLoading.value = false;
    }
  }

  Future<void> _fetchSingleStats(String contentId) async {
    try {
      final stats = await _interactionRepo.getInteractionStats(contentId);
      if (stats != null) {
        contentLikes[contentId] = stats['likes'] ?? 0;
      }
    } catch (e) {
      print("Error fetching stats for $contentId: $e");
    }
  }

  Future<void> fetchContentDetail(String id) async {
    try {
      isContentDetailLoading.value = true;
      final result = await _repository.getContentDetail(id);
      contentDetail.value = result;
      // Fetch stats only when content detail is loaded
      _fetchSingleStats(id);
    } catch (e) {
      print("Error in fetchContentDetail: $e");
    } finally {
      isContentDetailLoading.value = false;
    }
  }
}
