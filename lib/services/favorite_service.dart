// lib/services/favorite_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart' as models;
import '../utils/ip_detection.dart';
import 'auth_service.dart' as auth_service;

class FavoriteService {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  FavoriteService._internal();

  final _authService = auth_service.AuthService();

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<ApiResponse<List<models.Product>>> getFavorites() async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/favoritos/');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<models.Product> favorites = [];

        if (responseData is List) {
          favorites = responseData.map((item) => models.Product.fromJson(item['producto'])).toList();
        }

        return ApiResponse<List<models.Product>>(
          success: true,
          data: favorites,
          message: 'Favoritos obtenidos exitosamente',
        );
      } else {
        return ApiResponse<List<models.Product>>(
          success: false,
          error: 'Error al obtener favoritos: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<List<models.Product>>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<bool>> addToFavorites(int productId) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/favoritos/');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'producto': productId}),
      );

      if (response.statusCode == 201) {
        return ApiResponse<bool>(
          success: true,
          data: true,
          message: 'Producto agregado a favoritos',
        );
      } else {
        return ApiResponse<bool>(
          success: false,
          error: 'Error al agregar a favoritos: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<bool>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<bool>> removeFromFavorites(int favoriteId) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/favoritos/$favoriteId/');

      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse<bool>(
          success: true,
          data: false,
          message: 'Producto removido de favoritos',
        );
      } else {
        return ApiResponse<bool>(
          success: false,
          error: 'Error al remover de favoritos: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<bool>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<bool>> isFavorite(int productId) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/favoritos/verificar/$productId/');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final isFavorite = responseData['esta_en_favoritos'] ?? false;
        
        return ApiResponse<bool>(
          success: true,
          data: isFavorite,
          message: '',
        );
      } else {
        return ApiResponse<bool>(
          success: false,
          error: 'Error al verificar favorito',
        );
      }
    } catch (e) {
      return ApiResponse<bool>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? message;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
  });
}