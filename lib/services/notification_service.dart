import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io'; // Para Platform
import '../models/notification_model.dart';
import '../utils/ip_detection.dart';
import 'auth_service.dart' as auth_service;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _authService = auth_service.AuthService();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // ✅ MÉTODO FALTANTE: Registrar dispositivo después del login
  static Future<void> registerDeviceAfterLogin() async {
    try {
      final instance = NotificationService();
      print('🔄 Registrando dispositivo FCM después del login...');
      
      // Obtener el token FCM
      String? token = await instance._firebaseMessaging.getToken();
      
      if (token != null) {
        print('📱 Token FCM obtenido: $token');
        await instance._saveFCMTokenToBackend(token);
        print('✅ Dispositivo registrado exitosamente después del login');
      } else {
        print('⚠️ No se pudo obtener el token FCM después del login');
      }
    } catch (e) {
      print('❌ Error al registrar dispositivo después del login: $e');
      // No relanzar la excepción para no interrumpir el flujo de login
    }
  }

  // Método initialize
  static Future<void> initialize() async {
    try {
      final instance = NotificationService();
      
      // Solicitar permisos para notificaciones
      NotificationSettings settings = await instance._firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('Permisos de notificación: ${settings.authorizationStatus}');

      // Obtener y guardar el token FCM
      await instance._setupFCMToken();

      // Configurar manejadores de notificaciones
      await instance._setupNotificationHandlers();

      print('NotificationService inicializado correctamente');

    } catch (e) {
      print('Error inicializando NotificationService: $e');
      throw e;
    }
  }

  Future<void> _setupFCMToken() async {
    try {
      // Obtener el token FCM
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      if (token != null) {
        // Guardar el token en tu backend
        await _saveFCMTokenToBackend(token);
      }

      // Escuchar refrescos del token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('Nuevo FCM Token: $newToken');
        _saveFCMTokenToBackend(newToken);
      });

    } catch (e) {
      print('Error configurando FCM token: $e');
    }
  }

  Future<void> _saveFCMTokenToBackend(String token) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/guardar-token-fcm/');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'token': token,
          'dispositivo': 'mobile',
          'plataforma': Platform.operatingSystem, // Agregar plataforma
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Token FCM guardado en backend');
      } else {
        print('⚠️ Error guardando token FCM: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error guardando token en backend: $e');
    }
  }

  Future<void> _setupNotificationHandlers() async {
    // Manejar notificaciones en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Notificación en primer plano: ${message.notification?.title}');
      _handleForegroundNotification(message);
    });

    // Manejar cuando se toca la notificación y la app está en segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notificación tocada en segundo plano: ${message.notification?.title}');
      _handleBackgroundNotification(message);
    });

    // Manejar notificación cuando la app está totalmente cerrada
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('Notificación inicial: ${initialMessage.notification?.title}');
      _handleInitialNotification(initialMessage);
    }
  }

  void _handleForegroundNotification(RemoteMessage message) {
    // Aquí puedes mostrar un diálogo, snackbar o actualizar el estado
    // de notificaciones no leídas en tu app
    final notification = message.notification;
    final data = message.data;

    print('Título: ${notification?.title}');
    print('Cuerpo: ${notification?.body}');
    print('Data: $data');

    // Ejemplo: Mostrar un snackbar o actualizar contador
    // _showLocalNotification(notification);
  }

  void _handleBackgroundNotification(RemoteMessage message) {
    // Navegar a pantalla específica cuando el usuario toca la notificación
    final data = message.data;
    
    // Ejemplo: Navegar a detalles de pedido si viene en data
    if (data['tipo'] == 'pedido') {
      // Navigator.push(...);
    }
  }

  void _handleInitialNotification(RemoteMessage message) {
    // Similar a _handleBackgroundNotification pero para cuando
    // la app se abre desde totalmente cerrada
    _handleBackgroundNotification(message);
  }

  // Métodos existentes que ya tenías...
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

  // Método para limpiar el token FCM al cerrar sesión
  Future<void> clearFCMToken() async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/limpiar-token-fcm/');

      await http.post(url, headers: headers);
      print('Token FCM limpiado del backend');
    } catch (e) {
      print('Error limpiando token FCM: $e');
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