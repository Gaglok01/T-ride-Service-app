import 'dart:convert';

double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

class FoodPlacedOrderLineItem {
  FoodPlacedOrderLineItem({
    this.id,
    this.orderId,
    this.productId,
    this.productName,
    this.unitPrice,
    this.quantity,
    this.total,
    this.specialInstructions,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? orderId;
  final int? productId;
  final String? productName;
  final String? unitPrice;
  final int? quantity;
  final String? total;
  final String? specialInstructions;
  final String? createdAt;
  final String? updatedAt;

  factory FoodPlacedOrderLineItem.fromJson(Map<String, dynamic> json) {
    return FoodPlacedOrderLineItem(
      id: _parseInt(json['id']),
      orderId: _parseInt(json['order_id']),
      productId: _parseInt(json['product_id']),
      productName: json['product_name']?.toString(),
      unitPrice: json['unit_price']?.toString(),
      quantity: _parseInt(json['quantity']),
      total: json['total']?.toString(),
      specialInstructions: json['special_instructions']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

/// Response `data` from `POST api/app/food/order/place`.
class FoodPlacedOrderModel {
  FoodPlacedOrderModel({
    required this.orderCode,
    this.customerId,
    this.vendorId,
    this.categoryId,
    this.totalItems,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    required this.deliveryLat,
    required this.deliveryLng,
    required this.contactPhone,
    this.deliveryInstructions,
    required this.paymentMethod,
    required this.deliveryFee,
    this.updatedAt,
    this.createdAt,
    this.id,
    this.items = const [],
  });

  final String orderCode;
  final int? customerId;
  final int? vendorId;
  final int? categoryId;
  final int? totalItems;
  final String totalAmount;
  final String status;
  final String deliveryAddress;
  final double deliveryLat;
  final double deliveryLng;
  final String contactPhone;
  final String? deliveryInstructions;
  final String paymentMethod;
  final String deliveryFee;
  final String? updatedAt;
  final String? createdAt;
  final int? id;
  final List<FoodPlacedOrderLineItem> items;

  factory FoodPlacedOrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <FoodPlacedOrderLineItem>[];
    if (rawItems is List) {
      for (final e in rawItems) {
        if (e is Map<String, dynamic>) {
          items.add(FoodPlacedOrderLineItem.fromJson(e));
        }
      }
    }
    return FoodPlacedOrderModel(
      orderCode: json['order_code']?.toString() ?? '',
      customerId: _parseInt(json['customer_id']),
      vendorId: _parseInt(json['vendor_id']),
      categoryId: _parseInt(json['category_id']),
      totalItems: _parseInt(json['total_items']),
      totalAmount: json['total_amount']?.toString() ?? '0',
      status: json['status']?.toString() ?? '',
      deliveryAddress: json['delivery_address']?.toString() ?? '',
      deliveryLat: _parseDouble(json['delivery_lat']),
      deliveryLng: _parseDouble(json['delivery_lng']),
      contactPhone: json['contact_phone']?.toString() ?? '',
      deliveryInstructions: json['delivery_instructions']?.toString(),
      paymentMethod: json['payment_method']?.toString() ?? '',
      deliveryFee: json['delivery_fee']?.toString() ?? '0',
      updatedAt: json['updated_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      id: _parseInt(json['id']),
      items: items,
    );
  }

  static FoodPlacedOrderModel? tryParseResponseBody(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      if (decoded['status'] != true) return null;
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) return null;
      return FoodPlacedOrderModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
