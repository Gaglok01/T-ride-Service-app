import 'dart:convert';

bool? _parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.trim().toLowerCase();
    if (v == 'true' || v == '1') return true;
    if (v == 'false' || v == '0') return false;
  }
  return null;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _parseString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

class ProductDetails {
  bool? status;
  Data? data;

  ProductDetails({this.status, this.data});

  factory ProductDetails.fromJson(Map<String, dynamic> json) => ProductDetails(
        status: _parseBool(json['status']),
        data: json['data'] is Map<String, dynamic>
            ? Data.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );

  static ProductDetails fromJsonString(String source) =>
      ProductDetails.fromJson(jsonDecode(source) as Map<String, dynamic>);

  ProductDetails copyWith({bool? status, Data? data}) =>
      ProductDetails(status: status ?? this.status, data: data ?? this.data);
}

class Data {
  int? id;
  int? vendorId;
  String? name;
  String? description;
  dynamic country;
  dynamic city;
  String? price;
  String? salePrice;
  String? image;
  int? stock;
  String? sku;
  bool? isFeatured;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  Vendor? vendor;

  Data({
    this.id,
    this.vendorId,
    this.name,
    this.description,
    this.country,
    this.city,
    this.price,
    this.salePrice,
    this.image,
    this.stock,
    this.sku,
    this.isFeatured,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.vendor,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: _parseInt(json['id']),
        vendorId: _parseInt(json['vendor_id']),
        name: _parseString(json['name']),
        description: _parseString(json['description']),
        country: json['country'],
        city: json['city'],
        price: _parseString(json['price']),
        salePrice: _parseString(json['sale_price']),
        image: _parseString(json['image']),
        stock: _parseInt(json['stock']),
        sku: _parseString(json['sku']),
        isFeatured: _parseBool(json['is_featured']),
        isActive: _parseBool(json['is_active']),
        createdAt: _parseString(json['created_at']),
        updatedAt: _parseString(json['updated_at']),
        vendor: json['vendor'] is Map<String, dynamic>
            ? Vendor.fromJson(json['vendor'] as Map<String, dynamic>)
            : null,
      );

  Data copyWith({
    int? id,
    int? vendorId,
    String? name,
    String? description,
    dynamic country,
    dynamic city,
    String? price,
    String? salePrice,
    String? image,
    int? stock,
    String? sku,
    bool? isFeatured,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
    Vendor? vendor,
  }) => Data(
    id: id ?? this.id,
    vendorId: vendorId ?? this.vendorId,
    name: name ?? this.name,
    description: description ?? this.description,
    country: country ?? this.country,
    city: city ?? this.city,
    price: price ?? this.price,
    salePrice: salePrice ?? this.salePrice,
    image: image ?? this.image,
    stock: stock ?? this.stock,
    sku: sku ?? this.sku,
    isFeatured: isFeatured ?? this.isFeatured,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    vendor: vendor ?? this.vendor,
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
  });

  factory Vendor.fromJson(Map<String, dynamic> json) => Vendor(
        id: _parseInt(json['id']),
        userId: json['user_id'],
        categoryId: _parseInt(json['category_id']),
        name: _parseString(json['name']),
        address: _parseString(json['address']),
        lat: _parseString(json['lat']),
        lng: _parseString(json['lng']),
        deliveryRangeKm: _parseString(json['delivery_range_km']),
        minOrderAmount: _parseString(json['min_order_amount']),
        deliveryFee: _parseString(json['delivery_fee']),
        country: _parseString(json['country']),
        city: _parseString(json['city']),
        businessTimings: _parseString(json['business_timings']),
        logo: _parseString(json['logo']),
        totalOrders: _parseInt(json['total_orders']),
        totalRevenue: _parseString(json['total_revenue']),
        rating: _parseString(json['rating']),
        commissionRate: _parseString(json['commission_rate']),
        status: _parseInt(json['status']),
        isOpen: _parseInt(json['is_open']),
        isAvailableForDelivery: _parseInt(json['is_available_for_delivery']),
        createdAt: _parseString(json['created_at']),
        updatedAt: _parseString(json['updated_at']),
      );

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
  );
}
