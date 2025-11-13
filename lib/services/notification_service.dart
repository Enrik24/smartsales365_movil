// lib/services/notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../utils/ip_detection.dart';
import 'auth_service.dart' as auth_service;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _authService = auth_service.AuthService();

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Obtener todas las notificaciones
  Future<ApiResponse<List<AppNotification>>> getNotifications() async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/notificaciones/');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<AppNotification> notifications = [];

        if (responseData is List) {
          notifications = responseData.map((item) => AppNotification.fromJson(item)).toList();
        } else if (responseData['results'] != null) {
          notifications = (responseData['results'] as List)
              .map((item) => AppNotification.fromJson(item))
              .toList();
        }

        return ApiResponse<List<AppNotification>>(
          success: true,
          data: notifications,
          message: 'Notificaciones obtenidas exitosamente',
        );
      } else {
        return ApiResponse<List<AppNotification>>(
          success: false,
          error: 'Error al obtener notificaciones: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<List<AppNotification>>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  // Obtener notificaciones no leídas
  Future<ApiResponse<List<AppNotification>>> getUnreadNotifications() async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/notificaciones/no-leidas/');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<AppNotification> notifications = [];

        if (responseData is List) {
          notifications = responseData.map((item) => AppNotification.fromJson(item)).toList();
        }

        return ApiResponse<List<AppNotification>>(
          success: true,
          data: notifications,
          message: 'Notificaciones no leídas obtenidas',
        );
      } else {
        return ApiResponse<List<AppNotification>>(
          success: false,
          error: 'Error al obtener notificaciones no leídas: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<List<AppNotification>>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  // Marcar notificación como leída
  Future<ApiResponse<void>> markAsRead(int notificationId) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/notificaciones/marcar-leida/');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'notificacion_id': notificationId,
        }),
      );

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: 'Notificación marcada como leída',
        );
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse<void>(
          success: false,
          error: errorData['error'] ?? 'Error al marcar como leída: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  // Marcar todas como leídas
  Future<ApiResponse<void>> markAllAsRead() async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/notificaciones/marcar-todas-leidas/');

      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: 'Todas las notificaciones marcadas como leídas',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          error: 'Error al marcar todas como leídas: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  // Eliminar notificación
  Future<ApiResponse<void>> deleteNotification(int notificationId) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/notificaciones/$notificationId/');

      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse<void>(
          success: true,
          message: 'Notificación eliminada',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          error: 'Error al eliminar notificación: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
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