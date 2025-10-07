import 'dart:async';
import 'package:bytecart_app/models/account_summary.dart';
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

  static final StreamController<Map<String, String>> _profileStreamController =
  StreamController<Map<String, String>>.broadcast();

  static Stream<Map<String, String>> get onProfileChanged =>
      _profileStreamController.stream;

  static void _emitProfileChanged(String? name, String? email) {
    _profileStreamController.add({"name": name ?? "", "email": email ?? ""});
  }

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

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", data["token"]);

        final u = _extractUserMap(data);
        if (u != null) {
          final n = u["name"]?.toString();
          final e = u["email"]?.toString();
          if (n != null && n.isNotEmpty) await prefs.setString("user_name", n);
          if (e != null && e.isNotEmpty) await prefs.setString("user_email", e);
          _emitProfileChanged(n, e);
        }

        await fetchAndCacheProfile();

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

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", data["token"]);

        final u = _extractUserMap(data);
        if (u != null) {
          final n = u["name"]?.toString();
          final e = u["email"]?.toString();
          if (n != null && n.isNotEmpty) await prefs.setString("user_name", n);
          if (e != null && e.isNotEmpty) await prefs.setString("user_email", e);
          _emitProfileChanged(n, e);
        }

        await fetchAndCacheProfile();

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

    final products = await getProducts();

    final terms = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    bool _matches(Product p) {
      final fields =
      <String>[
        p.productName,
        p.brandName,
        if (p.categoryName != null) p.categoryName!,
        ...p.models.map((m) => m.modelName),
        ...p.models.expand((m) => m.colorList),
      ].map((s) => s.toLowerCase()).toList();

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

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    await prefs.remove("user_name");
    await prefs.remove("user_email");
    _emitProfileChanged("", "");
  }

  static Future<void> fetchAndCacheProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      if (token == null || token.isEmpty) return;

      final profile = await _fetchProfileFromAnyEndpoint(token);
      final name = profile["name"];
      final email = profile["email"];

      if (name != null && name.isNotEmpty) {
        await prefs.setString("user_name", name);
      }
      if (email != null && email.isNotEmpty) {
        await prefs.setString("user_email", email);
      }
      _emitProfileChanged(name, email);
    } catch (_) {}
  }

  static Future<Map<String, String>> getCachedUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "name": prefs.getString("user_name") ?? "",
      "email": prefs.getString("user_email") ?? "",
    };
  }

  static Future<Map<String, dynamic>> getAccountDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    if (token == null) throw ApiException("Not logged in");

    final response = await _dio.get(
      "/account/dashboard",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    } else {
      throw ApiException("Failed to load account dashboard");
    }
  }

  static Future<AccountSummary> getAccountSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null || token.isEmpty) {
      throw ApiException("Unauthorized. Please log in again.");
    }

    final res = await _dio.get(
      "/account/summary",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
      return AccountSummary.fromJson(res.data as Map<String, dynamic>);
    }
    throw ApiException("Failed to load account summary");
  }

  static Future<Map<String, dynamic>> getShippingInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null || token.isEmpty) throw ApiException("Not logged in");

    try {
      final res = await _dio.get(
        "/shipping-info",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map<String, dynamic>) {
          if (data["data"] is Map) {
            return Map<String, dynamic>.from(data["data"] as Map);
          }
          return data;
        }
        throw ApiException("Unexpected shipping info response");
      }
      throw ApiException("Failed to load shipping info");
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<void> updateShippingInfo(Map<String, dynamic> body) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null || token.isEmpty) throw ApiException("Not logged in");

    try {
      final res = await _dio.post(
        "/shipping-info/update",
        data: body,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (res.statusCode != 200) {
        throw ApiException("Failed to update shipping info");
      }
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<Map<String, dynamic>> getPaymentMethod() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null) throw ApiException("Not logged in");

    final res = await _dio.get(
      "/payment-methods",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    if (res.statusCode == 200 && res.data["data"] is Map) {
      return Map<String, dynamic>.from(res.data["data"]);
    }
    throw ApiException("Failed to load payment methods");
  }

  static Future<void> updatePaymentMethod(Map<String, dynamic> body) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null) throw ApiException("Not logged in");

    final payload = Map<String, dynamic>.from(body);
    if (payload["card_number"] != null) {
      final digits = payload["card_number"].toString().replaceAll(
        RegExp(r'\D'),
        '',
      );
      if (digits.length >= 12) {
        payload["card_number"] = digits;
      } else {
        payload.remove("card_number");
      }
    }
    payload.removeWhere(
          (k, v) =>
      v == null || (v is String && v
          .trim()
          .isEmpty),
    );

    final res = await _dio.post(
      "/payment-methods/update",
      data: payload,
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    if (res.statusCode != 200) {
      throw ApiException("Failed to update payment method");
    }
  }

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

  static Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null) throw ApiException("Not logged in");

    try {
      final res = await _dio.put(
        "/user/profile",
        data: {"name": name, "email": email},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (res.statusCode != 200) {
        throw ApiException("Failed to update profile");
      }

      await prefs.setString("user_name", name);
      await prefs.setString("user_email", email);

      _emitProfileChanged(name, email);
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null) throw ApiException("Not logged in");

    try {
      final res = await _dio.put(
        "/user/password",
        data: {
          "current_password": currentPassword,
          "password": newPassword,
          "password_confirmation": confirmPassword,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (res.statusCode != 200) {
        throw ApiException("Failed to change password");
      }
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<void> logoutOtherSessions(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null) throw ApiException("Not logged in");

    try {
      final res = await _dio.post(
        "/user/logout-others",
        data: {"password": password},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (res.statusCode != 200) {
        throw ApiException("Failed to logout from other devices");
      }
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<void> deleteAccount(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null) throw ApiException("Not logged in");

    try {
      final res = await _dio.delete(
        "/user",
        data: {"password": password},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (res.statusCode != 200) {
        throw ApiException("Failed to delete account");
      }

      await logout();
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<List<Map<String, dynamic>>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null || token.isEmpty) throw ApiException("Not logged in");

    try {
      final res = await _dio.get(
        "/orders",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (res.statusCode == 200) {
        final d = res.data;
        if (d is Map) {
          if (d["orders"] is List) {
            return (d["orders"] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
          if (d["data"] is List) {
            return (d["data"] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
        } else if (d is List) {
          return d.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
      throw ApiException("Failed to load orders");
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<Map<String, dynamic>> getOrderDetails(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null || token.isEmpty) throw ApiException("Not logged in");

    try {
      final res = await _dio.get(
        "/orders/$id",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (res.statusCode == 200) {
        final d = res.data;
        if (d is Map) {
          final o = d["order"] ?? d["data"] ?? d;
          if (o is Map) return Map<String, dynamic>.from(o);
        }
        throw ApiException("Unexpected order details response");
      }
      throw ApiException("Failed to load order details");
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<void> cancelOrder(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null || token.isEmpty) throw ApiException("Not logged in");

    try {
      final res = await _dio.post(
        "/orders/$id/cancel",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode != 200) throw ApiException("Cancel failed");
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<void> deliverOrder(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null || token.isEmpty) throw ApiException("Not logged in");

    try {
      final res = await _dio.post(
        "/orders/$id/deliver",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode != 200) throw ApiException("Deliver failed");
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<List<Map<String, dynamic>>> getWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null || token.isEmpty) throw ApiException("Not logged in");

    try {
      final res = await _dio.get(
        "/wishlist",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200) {
        final d = res.data;
        if (d is Map) {
          if (d["wishlist"] is List) {
            return (d["wishlist"] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
          if (d["data"] is List) {
            return (d["data"] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
        } else if (d is List) {
          return d.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        throw ApiException("Unexpected wishlist response");
      }
      throw ApiException("Failed to load wishlist");
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<void> removeFromWishlist(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null || token.isEmpty) throw ApiException("Not logged in");

    try {
      final res = await _dio.delete(
        "/wishlist/$productId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode != 200) {
        throw ApiException("Failed to remove from wishlist");
      }
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<void> toggleWishlist(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null || token.isEmpty) throw ApiException("Not logged in");

    try {
      final res = await _dio.post(
        "/wishlist/$productId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode != 200) {
        throw ApiException("Failed to toggle wishlist");
      }
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  static Future<T> _retry<T>(Future<T> Function() fn, {
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
        delay *= 2;
        attempt++;
      }
    }
  }

  static String _friendlyError(DioException e) {
    final extracted = _extractErrorMessage(e.response?.data);
    if (extracted != null && extracted
        .trim()
        .isNotEmpty) {
      return extracted;
    }

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

  static Map<String, dynamic>? _extractUserMap(Map<String, dynamic> data) {
    if (data["user"] is Map) return Map<String, dynamic>.from(data["user"]);
    if (data["data"] is Map) {
      final m = Map<String, dynamic>.from(data["data"]);
      if (m.containsKey("name") || m.containsKey("email")) return m;
    }
    if (data.containsKey("name") || data.containsKey("email")) return data;
    return null;
  }

  static Future<Map<String, String>> _fetchProfileFromAnyEndpoint(
      String token,) async {
    final endpoints = ["/user", "/me", "/profile"];
    for (final ep in endpoints) {
      try {
        final res = await _dio.get(
          ep,
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );
        if (res.statusCode == 200 && res.data is Map) {
          final raw = Map<String, dynamic>.from(res.data as Map);
          final userMap = _extractUserMap(raw) ?? raw;
          final name = userMap["name"]?.toString() ?? "";
          final email = userMap["email"]?.toString() ?? "";
          if (name.isNotEmpty || email.isNotEmpty) {
            return {"name": name, "email": email};
          }
        }
      } catch (_) {}
    }
    return {};
  }
}

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}
