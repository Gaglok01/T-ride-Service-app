import 'dart:convert';

class DiliveryHomeData {
  bool? status;
  DeliveryHomePayload? data;

  DiliveryHomeData({this.status, this.data});

  factory DiliveryHomeData.fromJson(Map<String, dynamic> json) {
    final s = json['status'];
    bool? status;
    if (s is bool) {
      status = s;
    } else if (s is num) {
      status = s != 0;
    }

    return DiliveryHomeData(
      status: status,
      data: json['data'] != null
          ? DeliveryHomePayload.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  static DiliveryHomeData fromJsonString(String source) {
    final decoded = Map<String, dynamic>.from(
      jsonDecode(source) as Map<dynamic, dynamic>,
    );
    return DiliveryHomeData.fromJson(decoded);
  }

  DiliveryHomeData copyWith({bool? status, DeliveryHomePayload? data}) =>
      DiliveryHomeData(status: status ?? this.status, data: data ?? this.data);
}

class DeliveryHomePayload {
  List<Category>? categories;
  List<Vendor>? vendors;

  DeliveryHomePayload({this.categories, this.vendors});

  factory DeliveryHomePayload.fromJson(Map<String, dynamic> json) {
    return DeliveryHomePayload(
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
      vendors: (json['vendors'] as List<dynamic>?)
          ?.map((e) => Vendor.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  DeliveryHomePayload copyWith({
    List<Category>? categories,
    List<Vendor>? vendors,
  }) => DeliveryHomePayload(
    categories: categories ?? this.categories,
    vendors: vendors ?? this.vendors,
  );
}

class Category {
  int? id;
  String? name;
  String? slug;
  String? icon;
  int? status;
  String? createdAt;
  String? updatedAt;

  Category({
    this.id,
    this.name,
    this.slug,
    this.icon,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      slug: json['slug'] as String?,
      icon: json['icon'] as String?,
      status: (json['status'] as num?)?.toInt(),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Category copyWith({
    int? id,
    String? name,
    String? slug,
    String? icon,
    int? status,
    String? createdAt,
    String? updatedAt,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    slug: slug ?? this.slug,
    icon: icon ?? this.icon,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class Vendor {
  int? id;
  dynamic userId;
  int? categoryId;
  String? name;
  String? address;
  String? lat;
  String? lng;
  String? deliveryRangeKm;
  String? minOrderAmount;
  String? deliveryFee;
  String? country;
  String? city;
  String? businessTimings;
  String? logo;
  int? totalOrders;
  String? totalRevenue;
  String? rating;
  String? commissionRate;
  int? status;
  int? isOpen;
  int? isAvailableForDelivery;
  String? createdAt;
  String? updatedAt;
  double? distance;

  Vendor({
    this.id,
    this.userId,
    this.categoryId,
    this.name,
    this.address,
    this.lat,
    this.lng,
    this.deliveryRangeKm,
    this.minOrderAmount,
    this.deliveryFee,
    this.country,
    this.city,
    this.businessTimings,
    this.logo,
    this.totalOrders,
    this.totalRevenue,
    this.rating,
    this.commissionRate,
    this.status,
    this.isOpen,
    this.isAvailableForDelivery,
    this.createdAt,
    this.updatedAt,
    this.distance,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    final distVal = json['distance'];
    double? distance;
    if (distVal is num) {
      distance = distVal.toDouble();
    }

    return Vendor(
      id: (json['id'] as num?)?.toInt(),
      userId: json['user_id'],
      categoryId: (json['category_id'] as num?)?.toInt(),
      name: json['name'] as String?,
      address: json['address'] as String?,
      lat: json['lat']?.toString(),
      lng: json['lng']?.toString(),
      deliveryRangeKm: json['delivery_range_km']?.toString(),
      minOrderAmount: json['min_order_amount']?.toString(),
      deliveryFee: json['delivery_fee']?.toString(),
      country: json['country'] as String?,
      city: json['city'] as String?,
      businessTimings: json['business_timings'] as String?,
      logo: json['logo'] as String?,
      totalOrders: (json['total_orders'] as num?)?.toInt(),
      totalRevenue: json['total_revenue']?.toString(),
      rating: json['rating']?.toString(),
      commissionRate: json['commission_rate']?.toString(),
      status: (json['status'] as num?)?.toInt(),
      isOpen: (json['is_open'] as num?)?.toInt(),
      isAvailableForDelivery: (json['is_available_for_delivery'] as num?)
          ?.toInt(),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      distance: distance,
    );
  }

  Vendor copyWith({
    int? id,
    dynamic userId,
    int? categoryId,
    String? name,
    String? address,
    String? lat,
    String? lng,
    String? deliveryRangeKm,
    String? minOrderAmount,
    String? deliveryFee,
    String? country,
    String? city,
    String? businessTimings,
    String? logo,
    int? totalOrders,
    String? totalRevenue,
    String? rating,
    String? commissionRate,
    int? status,
    int? isOpen,
    int? isAvailableForDelivery,
    String? createdAt,
    String? updatedAt,
    double? distance,
  }) => Vendor(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    address: address ?? this.address,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    deliveryRangeKm: deliveryRangeKm ?? this.deliveryRangeKm,
    minOrderAmount: minOrderAmount ?? this.minOrderAmount,
    deliveryFee: deliveryFee ?? this.deliveryFee,
    country: country ?? this.country,
    city: city ?? this.city,
    businessTimings: businessTimings ?? this.businessTimings,
    logo: logo ?? this.logo,
    totalOrders: totalOrders ?? this.totalOrders,
    totalRevenue: totalRevenue ?? this.totalRevenue,
    rating: rating ?? this.rating,
    commissionRate: commissionRate ?? this.commissionRate,
    status: status ?? this.status,
    isOpen: isOpen ?? this.isOpen,
    isAvailableForDelivery:
        isAvailableForDelivery ?? this.isAvailableForDelivery,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    distance: distance ?? this.distance,
  );
}
