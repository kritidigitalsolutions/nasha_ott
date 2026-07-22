class CategoryResponse {
  final bool success;
  final int count;
  final List<CategoryModel> categories;

  const CategoryResponse({
    required this.success,
    required this.count,
    required this.categories,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      success: json['success'] ?? false,
      count: json['count'] ?? 0,
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((e) => CategoryModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'count': count,
      'categories': categories.map((e) => e.toJson()).toList(),
    };
  }
}

class CategoryModel {
  final String id;
  final String slug;
  final String name;
  final bool isActive;
  final int priority;
  final int version;
  final String createdAt;
  final String updatedAt;

  const CategoryModel({
    required this.id,
    required this.slug,
    required this.name,
    required this.isActive,
    required this.priority,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? '',
      slug: json['slug'] ?? '',
      name: json['name'] ?? '',
      isActive: json['isActive'] ?? false,
      priority: json['priority'] ?? 0,
      version: json['__v'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'slug': slug,
      'name': name,
      'isActive': isActive,
      'priority': priority,
      '__v': version,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}