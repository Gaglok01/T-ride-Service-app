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

class VendorDetails {
  bool? status;
  Data? data;

  VendorDetails({this.status, this.data});

  factory VendorDetails.fromJson(Map<String, dynamic> json) => VendorDetails(
        status: _parseBool(json['status']),
        data: json['data'] is Map<String, dynamic>
            ? Data.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );

  static VendorDetails fromJsonString(String source) =>
      VendorDetails.fromJson(
        jsonDecode(source) as Map<String, dynamic>,
      );

  VendorDetails copyWith({bool? status, Data? data}) =>
      VendorDetails(status: status ?? this.status, data: data ?? this.data);
}

class Data {
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
  List<Product>? products;

  Data({
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
    this.products,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
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
        products: (json['products'] as List<dynamic>?)
            ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Data copyWith({
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
    List<Product>? products,
  }) => Data(
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
    products: products ?? this.products,
  );
}

class Product {
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

  Product({
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
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
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
      );

  Product copyWith({
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
  }) => Product(
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
  );
}
