class HelpResponse {
  final bool success;
  final int count;
  final List<HelpModel> helpData;

  HelpResponse({
    required this.success,
    required this.count,
    required this.helpData,
  });

  HelpResponse copyWith({
    bool? success,
    int? count,
    List<HelpModel>? helpData,
  }) {
    return HelpResponse(
      success: success ?? this.success,
      count: count ?? this.count,
      helpData: helpData ?? this.helpData,
    );
  }

  factory HelpResponse.fromJson(Map<String, dynamic> json) {
    return HelpResponse(
      success: json['success'] ?? false,
      count: json['count'] ?? 0,
      helpData: (json['helpData'] as List<dynamic>? ?? [])
          .map((e) => HelpModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'count': count,
      'helpData': helpData.map((e) => e.toJson()).toList(),
    };
  }
}

class HelpModel {
  final String id;
  final String category;
  final String question;
  final String answer;
  final String supportNumber;
  final String supportEmail;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  HelpModel({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required this.supportNumber,
    required this.supportEmail,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  HelpModel copyWith({
    String? id,
    String? category,
    String? question,
    String? answer,
    String? supportNumber,
    String? supportEmail,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? v,
  }) {
    return HelpModel(
      id: id ?? this.id,
      category: category ?? this.category,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      supportNumber: supportNumber ?? this.supportNumber,
      supportEmail: supportEmail ?? this.supportEmail,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
    );
  }

  factory HelpModel.fromJson(Map<String, dynamic> json) {
    return HelpModel(
      id: json['_id'] ?? '',
      category: json['category'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      supportNumber: json['supportNumber'] ?? '',
      supportEmail: json['supportEmail'] ?? '',
      isPublished: json['isPublished'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      v: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'category': category,
      'question': question,
      'answer': answer,
      'supportNumber': supportNumber,
      'supportEmail': supportEmail,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
    };
  }
}
