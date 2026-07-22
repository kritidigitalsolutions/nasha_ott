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
  final String title;
  final int priority;
  final List<ContentModel> content;

  CategorySection({
    required this.title,
    required this.priority,
    required this.content,
  });
}

class ContentController extends GetxController {
  final ContentRepository _repository = ContentRepository(NetworkApiService());
  final InteractionRepository _interactionRepo = InteractionRepository(
    NetworkApiService(),
  );

  var isLoading = true.obs;
  var isCategoryLoading = true.obs;

  var allContent = <ContentModel>[].obs;
  var allCategory = <CategoryModel>[].obs;

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
      final content = await _repository.getAllContent();

      // Sort content by priority (lower number = higher priority, e.g. 1 is top)
      content.sort((a, b) => (a.priority ?? 999).compareTo(b.priority ?? 999));

      allContent.assignAll(content);

      // Trending is a dedicated boolean flag, not part of `category` list
      trendingContent.assignAll(
        content
            .where((c) => c.isTrending == true && c.isComingSoon == false)
            .toList(),
      );

      // Fetch stats for each item to enable sorting by likes
      _fetchAllStats();
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
    } catch (e) {
      print("Error fetching categories: $e");
    } finally {
      isCategoryLoading.value = false;
    }
  }

  /// Builds an ORDERED list of category sections.
  /// - "trending" category -> filtered by content.isTrending
  /// - all other categories -> filtered by content.category.contains(slug)
  /// Order follows allCategory (already sorted ascending by priority),
  /// so priority 10 will always render above priority 11.
  void _buildCategorizedContent() {
    final List<CategorySection> sections = [];

    for (var cat in allCategory) {
      List<ContentModel> items;

      if (cat.slug.toLowerCase() == 'trending') {
        items = allContent
            .where((c) => c.isTrending == true && c.isComingSoon == false)
            .toList();
      } else {
        items = allContent
            .where(
              (c) => c.category.contains(cat.slug) && c.isComingSoon == false,
            )
            .toList();
      }

      if (items.isNotEmpty) {
        sections.add(
          CategorySection(
            title: cat.name,
            priority: cat.priority,
            content: items,
          ),
        );
      }
    }

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
}
