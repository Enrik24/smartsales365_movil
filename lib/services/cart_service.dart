import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart_model.dart';
import '../utils/ip_detection.dart';
import 'auth_service.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Obtener carrito del usuario
  Future<ApiResponse<Cart>> getCart() async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/carrito/');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final cart = Cart.fromJson(responseData);
        
        return ApiResponse<Cart>(
          success: true,
          data: cart,
          message: 'Carrito obtenido exitosamente',
        );
      } else {
        return ApiResponse<Cart>(
          success: false,
          error: 'Error al obtener carrito: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<Cart>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  // Agregar producto al carrito
  Future<ApiResponse<DetalleCarrito>> addToCart(int productoId, int cantidad) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/carrito/agregar/');

      final body = {
        'producto_id': productoId,
        'cantidad': cantidad,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final detalle = DetalleCarrito.fromJson(responseData);
        
        return ApiResponse<DetalleCarrito>(
          success: true,
          data: detalle,
          message: 'Producto agregado al carrito',
        );
      } else {
        return ApiResponse<DetalleCarrito>(
          success: false,
          error: 'Error al agregar producto al carrito',
        );
      }
    } catch (e) {
      return ApiResponse<DetalleCarrito>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  // Actualizar cantidad en carrito
  Future<ApiResponse<DetalleCarrito>> updateCartQuantity(int productoId, int cantidad) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/carrito/actualizar/$productoId/');

      final body = {
        'cantidad': cantidad,
      };

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final detalle = DetalleCarrito.fromJson(responseData);
        
        return ApiResponse<DetalleCarrito>(
          success: true,
          data: detalle,
          message: 'Cantidad actualizada',
        );
      } else {
        return ApiResponse<DetalleCarrito>(
          success: false,
          error: 'Error al actualizar cantidad',
        );
      }
    } catch (e) {
      return ApiResponse<DetalleCarrito>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  // Eliminar producto del carrito
  Future<ApiResponse<bool>> removeFromCart(int productoId) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/carrito/quitar/$productoId/');

      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        return ApiResponse<bool>(
          success: true,
          data: true,
          message: 'Producto eliminado del carrito',
        );
      } else {
        return ApiResponse<bool>(
          success: false,
          error: 'Error al eliminar producto del carrito',
        );
      }
    } catch (e) {
      return ApiResponse<bool>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  // Vaciar carrito
  Future<ApiResponse<bool>> clearCart() async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/carrito/vaciar/');

      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        return ApiResponse<bool>(
          success: true,
          data: true,
          message: 'Carrito vaciado',
        );
      } else {
        return ApiResponse<bool>(
          success: false,
          error: 'Error al vaciar carrito',
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