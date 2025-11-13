import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../utils/ip_detection.dart';
import 'auth_service.dart';

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

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // CORREGIDO: URL actualizada para coincidir con el backend Django
  Future<ApiResponse<List<Order>>> getOrders({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      
      final params = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (status != null && status.isNotEmpty) 'estado_pedido': status,
      };

      final queryString = Uri(queryParameters: params).query;
      // CORREGIDO: URL actualizada a /api/pedidos/
      final url = Uri.parse('$baseUrl/api/pedidos/?$queryString');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<Order> orders = [];

        if (responseData is List) {
          orders = responseData.map((item) => Order.fromJson(item)).toList();
        } else if (responseData['results'] != null) {
          orders = (responseData['results'] as List)
              .map((item) => Order.fromJson(item))
              .toList();
        } else {
          // Si viene como lista directa en el cuerpo
          orders = (responseData as List)
              .map((item) => Order.fromJson(item))
              .toList();
        }

        return ApiResponse<List<Order>>(
          success: true,
          data: orders,
          message: 'Pedidos obtenidos exitosamente',
        );
      } else {
        return ApiResponse<List<Order>>(
          success: false,
          error: 'Error al obtener pedidos: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<List<Order>>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  // CORREGIDO: Obtener detalle de un pedido
  Future<ApiResponse<Order>> getOrderDetail(int orderId) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      // CORREGIDO: URL actualizada a /api/pedidos/
      final url = Uri.parse('$baseUrl/api/pedidos/$orderId/');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final order = Order.fromJson(responseData);
        
        return ApiResponse<Order>(
          success: true,
          data: order,
          message: 'Pedido obtenido exitosamente',
        );
      } else {
        return ApiResponse<Order>(
          success: false,
          error: 'Error al obtener pedido: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<Order>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  // CORREGIDO: Crear un nuevo pedido
  Future<ApiResponse<Order>> createOrder(Map<String, dynamic> orderData) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      // CORREGIDO: URL actualizada a /api/pedidos/crear/
      final url = Uri.parse('$baseUrl/api/pedidos/crear/');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final order = Order.fromJson(responseData);
        
        return ApiResponse<Order>(
          success: true,
          data: order,
          message: 'Pedido creado exitosamente',
        );
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse<Order>(
          success: false,
          error: errorData['detail'] ?? errorData['error'] ?? 'Error al crear pedido',
        );
      }
    } catch (e) {
      return ApiResponse<Order>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  // AGREGADO: Obtener historial de seguimiento de pedido
  Future<ApiResponse<List<Map<String, dynamic>>>> getOrderTrackingHistory(int orderId) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      // CORREGIDO: URL según tu backend Django
      final url = Uri.parse('$baseUrl/api/pedidos/$orderId/seguimiento/');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<Map<String, dynamic>> trackingHistory = [];

        if (responseData is List) {
          trackingHistory = List<Map<String, dynamic>>.from(responseData);
        }

        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: trackingHistory,
          message: 'Historial de seguimiento obtenido exitosamente',
        );
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          error: 'Error al obtener historial de seguimiento: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  // AGREGADO: Confirmar pedido
  Future<ApiResponse<bool>> confirmOrder(int orderId) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/pedidos/$orderId/confirmar/');

      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        return ApiResponse<bool>(
          success: true,
          data: true,
          message: 'Pedido confirmado exitosamente',
        );
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse<bool>(
          success: false,
          error: errorData['error'] ?? 'Error al confirmar pedido',
        );
      }
    } catch (e) {
      return ApiResponse<bool>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  // AGREGADO: Cancelar pedido
  Future<ApiResponse<bool>> cancelOrder(int orderId, {String? motivo}) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/pedidos/$orderId/cancelar/');

      final body = {
        if (motivo != null) 'motivo': motivo,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return ApiResponse<bool>(
          success: true,
          data: true,
          message: 'Pedido cancelado exitosamente',
        );
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse<bool>(
          success: false,
          error: errorData['error'] ?? 'Error al cancelar pedido',
        );
      }
    } catch (e) {
      return ApiResponse<bool>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  // AGREGADO: Obtener comprobante de pedido
  Future<ApiResponse<Map<String, dynamic>>> getOrderReceipt(int orderId) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/pedidos/$orderId/comprobante/');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: responseData,
          message: 'Comprobante obtenido exitosamente',
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: 'Error al obtener comprobante: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  // AGREGADO: Procesar pago con Stripe
  Future<ApiResponse<Map<String, dynamic>>> processStripePayment(int orderId, Map<String, dynamic> paymentData) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/pedidos/$orderId/pago/');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(paymentData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: responseData,
          message: 'Pago procesado exitosamente',
        );
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: errorData['error'] ?? 'Error al procesar pago',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  // AGREGADO: Solicitar devolución
  Future<ApiResponse<Map<String, dynamic>>> requestRefund(int orderId, Map<String, dynamic> refundData) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/devoluciones/solicitar/');

      final body = {
        'pedido': orderId,
        ...refundData,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: responseData,
          message: 'Devolución solicitada exitosamente',
        );
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: errorData['error'] ?? 'Error al solicitar devolución',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }
}