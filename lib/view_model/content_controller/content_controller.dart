// ignore_for_file: avoid_print

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
    await Future.wait([fetchContent(), fetchCategory()]);
    _buildCategorizedContent();
  }

  Future<void> fetchContent() async {
    try {
      isLoading.value = true;
      final rawContent = await _repository.getAllContent();

      final content = rawContent.where((c) {
        if (c.isPublished != true) {
          return false;
        }
        if (c.is18Plus) {
          if (c.isHide == true) {
            return false;
          }
        }
        return true;
      }).toList();

      // Sort content by priority (lower number = higher priority, e.g. 1 is top)
      content.sort((a, b) => (a.priority ?? 999).compareTo(b.priority ?? 999));

      allContent.assignAll(content);

      // Trending is a dedicated boolean flag, not part of `category` list
      trendingContent.assignAll(
        content
            .where((c) => c.isTrending == true && c.isComingSoon == false)
            .toList(),
      );

      // -----------------------------
      // web banner content
      //-------------------------------------------------

      final webBannerContent = await _repository.getAllWebSiteBannerContent();
      allWebBannerContent.assignAll(webBannerContent);

      final sections = await _repository.getWebSections();
      webSections.assignAll(sections);

      // Fetch stats for each item to enable sorting by likes
      _fetchAllStats();
      _buildCategorizedContent();
    } catch (e) {
      print("Error in ContentController: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCategory() async {
    try {
      isCategoryLoading.value = true;
      final categories = await _repository.allCategory();

      // Only active categories.
      // Lower priority number = higher up (matches content.priority convention).
      final activeCategories = categories.where((c) => c.isActive).toList()
        ..sort((a, b) => a.priority.compareTo(b.priority));

      allCategory.assignAll(activeCategories);
      _buildCategorizedContent();
    } catch (e) {
      print("Error fetching categories: $e");
    } finally {
      isCategoryLoading.value = false;
    }
  }

  void _buildCategorizedContent() {
    final List<CategorySection> sections = [];

    // Normalize: lowercase, trim, collapse spaces/hyphens/underscores
    String normalize(String s) =>
        s.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');

    for (var cat in allCategory) {
      List<ContentModel> items;

      final normalizedSlug = normalize(cat.slug);

      if (normalizedSlug == 'trending') {
        // "trending" category uses isTrending flag
        items = allContent
            .where((c) => c.isTrending == true && c.isComingSoon == false)
            .toList();
      } else {
        // Match content.category values against category slug (case/space insensitive)
        items = allContent
            .where(
              (c) =>
                  c.category.any(
                    (catName) => normalize(catName) == normalizedSlug,
                  ) &&
                  c.isComingSoon == false,
            )
            .toList();
      }

      if (items.isNotEmpty) {
        sections.add(
          CategorySection(
            title: cat.name,
            priority: cat.priority,
            categorySlug: cat.slug,
            content: items,
          ),
        );
      }
    }

    // Sort sections: priority 1 = highest importance = shown first (ascending sort)
    sections.sort((a, b) => a.priority.compareTo(b.priority));

    categorySections.assignAll(sections);
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

  Future<void> _fetchAllStats() async {
    for (var item in allContent) {
      _fetchSingleStats(item.id);
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
    } catch (e) {
      print("Error in fetchContentDetail: $e");
    } finally {
      isContentDetailLoading.value = false;
    }
  }
}
