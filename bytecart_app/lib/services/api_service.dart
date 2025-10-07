import 'package:bytecart_app/models/filter.dart';
import 'package:bytecart_app/models/product.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://10.0.2.2:8000/api",
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      headers: {"Accept": "application/json"},
    ),
  );

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.post(
        "/register",
        data: {
          "name": name,
          "email": email,
          "password": password,
          "password_confirmation": confirmPassword,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;

        // save token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", data["token"]);

        return data;
      } else {
        throw ApiException(
          "Failed to register. Status code: ${response.statusCode}",
        );
      }
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        "/login",
        data: {"email": email, "password": password},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Save token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", data["token"]);

        return data;
      } else {
        throw ApiException("Login failed. Status: ${response.statusCode}");
      }
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<List<Product>> getProducts() async {
    try {
      return await _retry<List<Product>>(() async {
        final response = await _dio.get("/products");
        if (response.statusCode == 200) {
          final raw = response.data;
          final List list =
              raw is List
                  ? raw
                  : (raw is Map && raw['data'] is List)
                  ? (raw['data'] as List)
                  : throw ApiException("Unexpected products response format");
          return list
              .map((p) => Product.fromJson(p as Map<String, dynamic>))
              .toList();
        } else {
          throw ApiException(
            "Failed to load products (${response.statusCode})",
          );
        }
      });
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<Product> getProductDetail(int id) async {
    try {
      return await _retry<Product>(() async {
        final response = await _dio.get("/products/$id");
        if (response.statusCode == 200) {
          final raw = response.data;
          final Map<String, dynamic> map =
              raw is Map<String, dynamic>
                  ? (raw['data'] is Map
                      ? (raw['data'] as Map).cast<String, dynamic>()
                      : raw)
                  : throw ApiException("Unexpected product response format");
          return Product.fromJson(map);
        } else {
          throw ApiException("Failed to load product (${response.statusCode})");
        }
      });
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<List<Product>> searchProducts(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return getProducts();
    }

    // Get all products and filter locally across brand, category, product name and colour
    final products = await getProducts();

    // Tokenize search query to support multi-word search (all terms must match at least one field)
    final terms = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    bool _matches(Product p) {
      // Collect searchable fields
      final fields =
          <String>[
            p.productName,
            p.brandName,
            if (p.categoryName != null) p.categoryName!,
            // Include model names and colors to cover "colour"
            ...p.models.map((m) => m.modelName),
            ...p.models.expand((m) => m.colorList),
          ].map((s) => s.toLowerCase()).toList();

      // Each term must exist in any field
      return terms.every((t) => fields.any((f) => f.contains(t)));
    }

    return products.where(_matches).toList();
  }

  static Future<List<Product>> getFilteredProducts(ShopFilter f) async {
    try {
      final response = await _dio.get(
        "/products/filter",
        queryParameters: {
          if (f.category.isNotEmpty) "category": f.category,
          if (f.brand.isNotEmpty) "brand": f.brand,
          if (f.color.isNotEmpty) "color": f.color,
          if (f.minPrice != null) "min_price": f.minPrice,
          if (f.maxPrice != null) "max_price": f.maxPrice,
          if (f.inStock) "in_stock": "1",
          if (f.sort.isNotEmpty) "sort": f.sort,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List list = data is List ? data : [];
        return list.map((p) => Product.fromJson(p)).toList();
      } else {
        throw ApiException("Failed to filter products");
      }
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<Map<String, dynamic>> addToCart({
    required int modelId,
    required int qty,
    String? color,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null) {
        throw ApiException("Please log in to add items to your cart.");
      }

      final response = await _dio.post(
        "/cart/add",
        data: {
          "model_id": modelId,
          "qty": qty,
          if (color != null && color.isNotEmpty) "color": color,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ApiException("Failed to add to cart.");
      }
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<List<Map<String, dynamic>>> getCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null || token.isEmpty) {
        throw ApiException("User not logged in");
      }

      final response = await _dio.get(
        "/cart",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map && data.containsKey('items')) {
          final rawItems = data['items'];

          // ✅ Laravel returns items as a Map (not List)
          if (rawItems is Map) {
            return rawItems.values
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          } else if (rawItems is List) {
            return rawItems.map((e) => Map<String, dynamic>.from(e)).toList();
          }
        }

        return [];
      } else {
        throw ApiException("Failed to fetch cart items");
      }
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<void> removeFromCart(String lineId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null || token.isEmpty) {
        throw ApiException("User not logged in");
      }

      final response = await _dio.post(
        "/cart/remove",
        data: {"line_id": lineId},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode != 200) {
        throw ApiException("Failed to remove item from cart");
      }
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<Map<String, dynamic>> updateCartItem({
    required String lineId,
    required int qty,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null || token.isEmpty) {
        throw ApiException("User not logged in");
      }

      final response = await _dio.post(
        "/cart/update",
        data: {"line_id": lineId, "qty": qty},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ApiException("Failed to update cart item");
      }
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<Map<String, dynamic>> clearCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null || token.isEmpty) {
        throw ApiException("User not logged in");
      }

      final response = await _dio.post(
        "/cart/clear",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ApiException("Failed to clear cart");
      }
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  // Add: simple auth state helpers
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
  }

  // Small typed exception so UI can show clean messages.
  // ignore: one_member_abstracts
  static String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map) {
      if (data['message'] is String) return data['message'] as String;
      if (data['error'] is String) return data['error'] as String;
      if (data['errors'] is Map) {
        final Map errs = data['errors'] as Map;
        final parts = <String>[];
        errs.forEach((_, v) {
          if (v is List && v.isNotEmpty) {
            parts.add(v.first.toString());
          } else if (v is String) {
            parts.add(v);
          }
        });
        if (parts.isNotEmpty) return parts.join('\n');
      }
    }
    return null;
  }

  // Retry transient errors (timeouts, connection issues, 5xx).
  static Future<T> _retry<T>(
    Future<T> Function() fn, {
    int retries = 2,
    Duration initialDelay = const Duration(milliseconds: 300),
  }) async {
    int attempt = 0;
    var delay = initialDelay;
    while (true) {
      try {
        return await fn();
      } on DioException catch (e) {
        final transient =
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError ||
            ((e.response?.statusCode ?? 0) >= 500);
        if (!transient || attempt >= retries) {
          rethrow;
        }
        await Future.delayed(delay);
        delay *= 2; // simple exponential backoff
        attempt++;
      }
    }
  }

  static String _friendlyError(DioException e) {
    // Prefer server-provided message if available
    final extracted = _extractErrorMessage(e.response?.data);
    if (extracted != null && extracted.trim().isNotEmpty) {
      return extracted;
    }

    // Then provide readable fallbacks by error type
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return "Connection timed out. Please try again.";
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        if (code >= 500) return "Server is unavailable. Please retry.";
        if (code == 404) return "Resource not found.";
        if (code == 401) return "Unauthorized. Please log in again.";
        return "Request failed with status $code.";
      case DioExceptionType.cancel:
        return "Request was cancelled.";
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
      default:
        return "Unable to connect to the server. Check your connection and try again.";
    }
  }
}

// Simple exception carrying a readable message.
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}
