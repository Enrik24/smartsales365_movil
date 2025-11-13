import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../utils/ip_detection.dart';
import 'auth_service.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Obtener productos
  Future<ApiResponse<List<Product>>> getProducts({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? category,
    String? sortBy,
  }) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      
      final params = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty && category != 'Todos') 'categoria': category,
        if (sortBy != null && sortBy.isNotEmpty) 'ordering': sortBy,
      };

      final queryString = Uri(queryParameters: params).query;
      final url = Uri.parse('$baseUrl/api/productos/?$queryString');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<Product> products = [];

        if (responseData is List) {
          products = responseData.map((item) => Product.fromJson(item)).toList();
        } else if (responseData['results'] != null) {
          products = (responseData['results'] as List)
              .map((item) => Product.fromJson(item))
              .toList();
        }

        return ApiResponse<List<Product>>(
          success: true,
          data: products,
          message: 'Productos obtenidos exitosamente',
        );
      } else {
        return ApiResponse<List<Product>>(
          success: false,
          error: 'Error al obtener productos: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<List<Product>>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  // Obtener categorías
  Future<ApiResponse<List<Categoria>>> getCategories() async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/categorias/');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<Categoria> categories = [];

        if (responseData is List) {
          categories = responseData.map((item) => Categoria.fromJson(item)).toList();
        }

        return ApiResponse<List<Categoria>>(
          success: true,
          data: categories,
          message: 'Categorías obtenidas exitosamente',
        );
      } else {
        return ApiResponse<List<Categoria>>(
          success: false,
          error: 'Error al obtener categorías: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<List<Categoria>>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  // Agregar a favoritos
  Future<ApiResponse<bool>> toggleFavorite(int productId) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/favoritos/toggle/');

      final body = {
        'producto_id': productId,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<bool>(
          success: true,
          data: true,
          message: 'Favorito actualizado',
        );
      } else {
        return ApiResponse<bool>(
          success: false,
          error: 'Error al actualizar favorito',
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

class Categoria {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? imagenUrl;

  Categoria({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.imagenUrl,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      imagenUrl: json['imagen_url'],
    );
  }
}