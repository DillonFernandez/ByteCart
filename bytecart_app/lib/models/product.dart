import 'dart:convert';

class ProductModel {
  final int id;
  final String modelName;
  final double price;
  final int stock;
  final String? colors;
  final List<String> images;

  ProductModel({
    required this.id,
    required this.modelName,
    required this.price,
    required this.stock,
    this.colors,
    required this.images,
  });

  List<String> get colorList {
    if (colors == null || colors!.isEmpty) return [];
    try {
      final decoded = jsonDecode(colors!);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {
      return colors!
          .split(',')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
    }
    return [colors!];
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    int _asInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    double _asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    List<String> _parseImages(dynamic v) {
      if (v == null) return <String>[];
      try {
        if (v is String) {
          final decoded = jsonDecode(v);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
          return <String>[];
        } else if (v is List) {
          return v.map((e) => e.toString()).toList();
        }
      } catch (_) {
        if (v is String && v.isNotEmpty) return <String>[v];
      }
      return <String>[];
    }

    return ProductModel(
      id: _asInt(json['id']),
      modelName: (json['model_name'] ?? '').toString(),
      price: _asDouble(json['price']),
      stock: _asInt(json['stock']),
      colors: json['colors']?.toString(),
      images: _parseImages(json['images']),
    );
  }
}

class Product {
  final int id;
  final String productName;
  final String brandName;
  final String? description;
  final String? specification;
  final String? image;
  final int discount;
  final bool newStock;
  final DateTime? createdAt;
  final List<ProductModel> models;
  final String? categoryName;

  Product({
    required this.id,
    required this.productName,
    required this.brandName,
    this.description,
    this.specification,
    this.image,
    required this.discount,
    required this.newStock,
    this.createdAt,
    required this.models,
    this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    int _asInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    bool _asBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase();
        return s == 'true' || s == '1' || s == 'yes';
      }
      return false;
    }

    DateTime? _asDate(dynamic v) {
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final dynamic modelsRaw = json['models'];
    final List<ProductModel> models =
    (modelsRaw is List)
        ? modelsRaw
        .whereType<Map<String, dynamic>>()
        .map((m) => ProductModel.fromJson(m))
        .toList()
        : <ProductModel>[];

    final int parsedDiscount = _asInt(json['discount'] ?? 0);
    final int clampedDiscount =
    parsedDiscount < 0 ? 0 : (parsedDiscount > 100 ? 100 : parsedDiscount);

    return Product(
      id: _asInt(json['id']),
      productName: (json['product_name'] ?? '').toString(),
      brandName: (json['brand_name'] ?? '').toString(),
      description: json['description']?.toString(),
      specification: json['specification']?.toString(),
      image: json['image']?.toString(),
      discount: clampedDiscount,
      newStock: _asBool(json['new_stock']),
      createdAt: _asDate(json['created_at']),
      models: models,
      categoryName: (json['category_name'] ?? json['category'])?.toString(),
    );
  }
}
