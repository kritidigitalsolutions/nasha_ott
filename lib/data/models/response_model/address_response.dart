class AddressResponse {
  final bool success;
  final AddressData data;

  AddressResponse({
    required this.success,
    required this.data,
  });

  AddressResponse copyWith({
    bool? success,
    AddressData? data,
  }) {
    return AddressResponse(
      success: success ?? this.success,
      data: data ?? this.data,
    );
  }

  factory AddressResponse.fromJson(Map<String, dynamic> json) {
    return AddressResponse(
      success: json['success'] ?? false,
      data: AddressData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.toJson(),
    };
  }
}

class AddressData {
  final String id;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final String googleMapUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  AddressData({
    required this.id,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.googleMapUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  AddressData copyWith({
    String? id,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? googleMapUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? v,
  }) {
    return AddressData(
      id: id ?? this.id,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      googleMapUrl: googleMapUrl ?? this.googleMapUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
    );
  }

  factory AddressData.fromJson(Map<String, dynamic> json) {
    return AddressData(
      id: json['_id'] ?? '',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      postalCode: json['postalCode'] ?? '',
      googleMapUrl: json['googleMapUrl'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      v: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
      'googleMapUrl': googleMapUrl,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
    };
  }
}