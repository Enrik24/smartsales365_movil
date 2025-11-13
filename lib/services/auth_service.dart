  import 'dart:convert';
  import 'package:http/http.dart' as http;
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:fluttertoast/fluttertoast.dart';
  import 'package:flutter/material.dart';
  import '../utils/ip_detection.dart';

  // Modelos actualizados para coincidir con tu backend Django
  class User {
    final int id;
    final String email;
    final String nombre;
    final String apellido;
    final String? telefono;
    final String? direccion;
    final String estado;
    final bool isActive;
    final DateTime fechaRegistro;
    final DateTime? ultimoLogin;
    final bool isAdmin;
    final String role; // Asumiendo que tu backend tiene este campo

    User({
      required this.id,
      required this.email,
      required this.nombre,
      required this.apellido,
      this.telefono,
      this.direccion,
      required this.estado,
      required this.isActive,
      required this.fechaRegistro,
      this.ultimoLogin,
      required this.isAdmin,
      required this.role, 
    });

    factory User.fromJson(Map<String, dynamic> json) {
      return User(
        id: json['id'] ?? 0,
        email: json['email'] ?? '',
        nombre: json['nombre'] ?? json['first_na  me'] ?? '',
        apellido: json['apellido'] ?? json['last_name'] ?? '',
        telefono: json['telefono'],
        direccion: json['direccion'],
        estado: json['estado'] ?? 'activo',
        isActive: json['is_active'] ?? true,
        fechaRegistro: DateTime.parse(json['fecha_registro'] ?? json['date_joined'] ?? DateTime.now().toIso8601String()),
        ultimoLogin: json['ultimo_login'] != null 
            ? DateTime.parse(json['ultimo_login']) 
            : json['last_login'] != null
              ? DateTime.parse(json['last_login'])
              : null,
        isAdmin: false,
        role: json['role'] ?? json['rol'] ?? 'user',
      );
    }

    Map<String, dynamic> toJson() {
      return {
        'id': id,
        'email': email,
        'nombre': nombre,
        'apellido': apellido,
        'telefono': telefono,
        'direccion': direccion,
        'estado': estado,
        'is_active': isActive,
        'fecha_registro': fechaRegistro.toIso8601String(),
        'ultimo_login': ultimoLogin?.toIso8601String(),
        'is_admin': isAdmin,
         'role': role,
      };
    }
    // Método copyWith
  User copyWith({
    int? id,
    String? email,
    String? nombre,
    String? apellido,
    String? telefono,
    String? direccion,
    String? estado,
    bool? isActive,
    DateTime? fechaRegistro,
    DateTime? ultimoLogin,
    bool? isAdmin,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      estado: estado ?? this.estado,
      isActive: isActive ?? this.isActive,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      ultimoLogin: ultimoLogin ?? this.ultimoLogin,
      isAdmin: isAdmin ?? this.isAdmin,
      role: role ?? this.role,
    );

  }
    String get fullName => '$nombre $apellido';
    String get firstName => nombre;
  }

  class LoginCredentials {
    final String email;
    final String password;

    LoginCredentials({
      required this.email,
      required this.password,
    });

    Map<String, dynamic> toJson() {
      return {
        'email': email,
        'password': password,
      };
    }
  }

  class RegisterData {
    final String email;
    final String nombre;
    final String apellido;
    final String password;
    final String? telefono;
    final String? direccion;

    RegisterData({
      required this.email,
      required this.nombre,
      required this.apellido,
      required this.password,
      this.telefono,
      this.direccion,
    });

    Map<String, dynamic> toJson() {
      return {
        'email': email,
        'nombre': nombre,
        'apellido': apellido,
        'password': password,
        'telefono': telefono,
        'direccion': direccion,
      };
    }
  }

  class LoginResponse {
    final String access;
    final String refresh;
    final User user;

    LoginResponse({
      required this.access,
      required this.refresh,
      required this.user,
    });

    factory LoginResponse.fromJson(Map<String, dynamic> json) {
      return LoginResponse(
        access: json['access'] ?? '',
        refresh: json['refresh'] ?? '',
        user: User.fromJson(json['usuario'] ?? json['user'] ?? {}),
      );
    }

    // Para compatibilidad con tu código existente
    String get tipoLogin => 'email'; // Por defecto
  }

  class AuthService {
    static final AuthService _instance = AuthService._internal();
    factory AuthService() => _instance;
    AuthService._internal();

    // Headers por defecto
    Map<String, String> get _defaultHeaders => {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Headers con autenticación
    Future<Map<String, String>> get _authHeaders async {
      final token = await getToken();
      final headers = Map<String, String>.from(_defaultHeaders);
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      return headers;
    }

    // ✅ Login usando el endpoint correcto de tu backend
    Future<ApiResponse<LoginResponse>> login(LoginCredentials credentials) async {
      try {
        final baseUrl = await IPDetection.getBaseUrl();
        final url = Uri.parse('$baseUrl/api/users/login/');
        
        final response = await http.post(
          url,
          headers: _defaultHeaders,
          body: jsonEncode(credentials.toJson()),
        ).timeout(const Duration(seconds: 10));

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          final loginResponse = LoginResponse.fromJson(responseData);
          
          // Guardar tokens
          await saveToken(loginResponse.access);
          await saveRefreshToken(loginResponse.refresh);

          return ApiResponse<LoginResponse>(
            success: true,
            data: loginResponse,
            message: 'Inicio de sesión exitoso',
          );
        } else {
          String errorMessage = 'Error en el login';
          if (responseData['detail'] != null) {
            errorMessage = responseData['detail'];
          } else if (responseData['error'] != null) {
            errorMessage = responseData['error'];
          } else if (responseData['non_field_errors'] != null) {
            errorMessage = responseData['non_field_errors'].join(', ');
          }
          return ApiResponse<LoginResponse>(
            success: false,
            error: errorMessage,
          );
        }
      } catch (e) {
        return ApiResponse<LoginResponse>(
          success: false,
          error: 'Error de conexión: $e',
        );
      }
    }
    // ✅ Registro de cliente específico
  Future<ApiResponse<LoginResponse>> registerCliente(Map<String, dynamic> userData) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final url = Uri.parse('$baseUrl/api/users/registro-cliente/');
      
      final response = await http.post(
        url,
        headers: _defaultHeaders,
        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final loginResponse = LoginResponse.fromJson(responseData);
        
        // Guardar tokens automáticamente después del registro
        await saveToken(loginResponse.access);
        await saveRefreshToken(loginResponse.refresh);

        return ApiResponse<LoginResponse>(
          success: true,
          data: loginResponse,
          message: 'Cliente registrado exitosamente',
        );
      } else {
        String errorMessage = 'Error en el registro del cliente';
        if (responseData['detail'] != null) {
          errorMessage = responseData['detail'];
        } else if (responseData['error'] != null) {
          errorMessage = responseData['error'];
        } else {
          // Manejar errores de validación de campos
          List<String> fieldErrors = [];
          responseData.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              fieldErrors.add('${_formatFieldName(key)}: ${value.join(', ')}');
            }
          });
          if (fieldErrors.isNotEmpty) {
            errorMessage = fieldErrors.join('; ');
          }
        }
        return ApiResponse<LoginResponse>(
          success: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      return ApiResponse<LoginResponse>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

    // ✅ Registro usando el endpoint correcto
    Future<ApiResponse<LoginResponse>> register(RegisterData userData) async {
      try {
        final baseUrl = await IPDetection.getBaseUrl();
        final url = Uri.parse('$baseUrl/api/users/registro/');
        
        final response = await http.post(
          url,
          headers: _defaultHeaders,
          body: jsonEncode(userData.toJson()),
        ).timeout(const Duration(seconds: 10));

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 201) {
          final loginResponse = LoginResponse.fromJson(responseData);
          
          // Guardar tokens automáticamente después del registro
          await saveToken(loginResponse.access);
          await saveRefreshToken(loginResponse.refresh);

          return ApiResponse<LoginResponse>(
            success: true,
            data: loginResponse,
            message: 'Cuenta creada exitosamente',
          );
        } else {
          String errorMessage = 'Error en el registro';
          if (responseData['detail'] != null) {
            errorMessage = responseData['detail'];
          } else if (responseData['error'] != null) {
            errorMessage = responseData['error'];
          } else {
            // Manejar errores de validación de campos
            List<String> fieldErrors = [];
            responseData.forEach((key, value) {
              if (value is List && value.isNotEmpty) {
                fieldErrors.add('${_formatFieldName(key)}: ${value.join(', ')}');
              }
            });
            if (fieldErrors.isNotEmpty) {
              errorMessage = fieldErrors.join('; ');
            }
          }
          return ApiResponse<LoginResponse>(
            success: false,
            error: errorMessage,
          );
        }
      } catch (e) {
        return ApiResponse<LoginResponse>(
          success: false,
          error: 'Error de conexión: $e',
        );
      }
    }

    // ✅ Obtener usuario actual usando el endpoint correcto
    Future<ApiResponse<User>> getCurrentUser() async {
      try {
        final baseUrl = await IPDetection.getBaseUrl();
        final url = Uri.parse('$baseUrl/api/users/usuarios/me/');
        final headers = await _authHeaders;
        
        final response = await http.get(
          url,
          headers: headers,
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final user = User.fromJson(responseData);
          return ApiResponse<User>(
            success: true,
            data: user,
          );
        } else if (response.statusCode == 401) {
          // Token inválido o expirado
          await clearTokens();
          return ApiResponse<User>(
            success: false,
            error: 'Sesión expirada. Por favor inicia sesión nuevamente.',
          );
        } else {
          return ApiResponse<User>(
            success: false,
            error: 'Error al obtener usuario',
          );
        }
      } catch (e) {
        return ApiResponse<User>(
          success: false,
          error: 'Error de conexión: $e',
        );
      }
    }

    // ✅ Logout usando el endpoint correcto
    Future<ApiResponse<void>> logout() async {
      try {
        final refreshToken = await getRefreshToken();
        if (refreshToken != null) {
          final baseUrl = await IPDetection.getBaseUrl();
          final url = Uri.parse('$baseUrl/api/users/logout/');
          final headers = await _authHeaders;
          
          final response = await http.post(
            url,
            headers: headers,
            body: jsonEncode({'refresh_token': refreshToken}),
          );

          if (response.statusCode == 205) {
            return ApiResponse<void>(
              success: true,
              message: 'Sesión cerrada exitosamente',
            );
          }
        }
        
        // Si no hay refresh token o falla el logout en el servidor, limpiar localmente
        await clearTokens();
        return ApiResponse<void>(
          success: true,
          message: 'Sesión cerrada',
        );
        
      } catch (e) {
        // En caso de error, limpiar tokens localmente
        await clearTokens();
        return ApiResponse<void>(
          success: true,
          message: 'Sesión cerrada',
        );
      }
    }

    // ✅ Refrescar token
    Future<ApiResponse<String>> refreshToken() async {
      try {
        final refreshToken = await getRefreshToken();
        if (refreshToken == null) {
          return ApiResponse<String>(
            success: false,
            error: 'No hay token de refresh disponible',
          );
        }

        final baseUrl = await IPDetection.getBaseUrl();
        final url = Uri.parse('$baseUrl/api/users/token/refresh/');
        
        final response = await http.post(
          url,
          headers: _defaultHeaders,
          body: jsonEncode({'refresh': refreshToken}),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final newAccessToken = responseData['access'];
          await saveToken(newAccessToken);
          
          return ApiResponse<String>(
            success: true,
            data: newAccessToken,
          );
        } else {
          await clearTokens();
          return ApiResponse<String>(
            success: false,
            error: 'Error al refrescar token',
          );
        }
      } catch (e) {
        await clearTokens();
        return ApiResponse<String>(
          success: false,
          error: 'Error de conexión: $e',
        );
      }
    }
    // ✅ Método para reenviar código de verificación
  Future<ApiResponse<void>> resendVerificationCode(int userId) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final url = Uri.parse('$baseUrl/api/users/reenviar-codigo-verificacion/');
      
      final response = await http.post(
        url,
        headers: _defaultHeaders,
        body: jsonEncode({
          'user_id': userId,
        }),
      ).timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: 'Código de verificación enviado exitosamente',
        );
      } else {
        String errorMessage = 'Error al enviar código de verificación';
        if (responseData['detail'] != null) {
          errorMessage = responseData['detail'];
        } else if (responseData['error'] != null) {
          errorMessage = responseData['error'];
        }
        return ApiResponse<void>(
          success: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  // ✅ Método para verificar código
  Future<ApiResponse<LoginResponse>> verifyCode(int userId, String code) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final url = Uri.parse('$baseUrl/api/users/verificar-codigo/');
      
      final response = await http.post(
        url,
        headers: _defaultHeaders,
        body: jsonEncode({
          'user_id': userId,
          'codigo': code,
        }),
      ).timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(responseData);
        
        // Guardar tokens después de la verificación exitosa
        await saveToken(loginResponse.access);
        await saveRefreshToken(loginResponse.refresh);

        return ApiResponse<LoginResponse>(
          success: true,
          data: loginResponse,
          message: 'Email verificado exitosamente',
        );
      } else {
        String errorMessage = 'Código de verificación incorrecto';
        if (responseData['detail'] != null) {
          errorMessage = responseData['detail'];
        } else if (responseData['error'] != null) {
          errorMessage = responseData['error'];
        }
        return ApiResponse<LoginResponse>(
          success: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      return ApiResponse<LoginResponse>(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

    // ✅ Cambiar contraseña
    Future<ApiResponse<void>> changePassword({
      required String currentPassword,
      required String newPassword,
    }) async {
      try {
        final baseUrl = await IPDetection.getBaseUrl();
        final url = Uri.parse('$baseUrl/api/users/cambiar-password/');
        final headers = await _authHeaders;
        
        final response = await http.post(
          url,
          headers: headers,
          body: jsonEncode({
            'password_actual': currentPassword,
            'nuevo_password': newPassword,
          }),
        );

        if (response.statusCode == 200) {
          return ApiResponse<void>(
            success: true,
            message: 'Contraseña cambiada exitosamente',
          );
        } else {
          final responseData = jsonDecode(response.body);
          String errorMessage = 'Error al cambiar contraseña';
          if (responseData['error'] != null) {
            errorMessage = responseData['error'];
          }
          return ApiResponse<void>(
            success: false,
            error: errorMessage,
          );
        }
      } catch (e) {
        return ApiResponse<void>(
          success: false,
          error: 'Error de conexión: $e',
        );
      }
    }

    // ✅ Login con Google (para compatibilidad con tu código existente)
    Future<ApiResponse<LoginResponse>> loginWithGoogle(String googleToken) async {
      try {
        // Simular login con Google - en producción integrar con el backend
        await Future.delayed(const Duration(seconds: 2));
        
        // Por ahora, devolver un error ya que no está implementado
        return ApiResponse<LoginResponse>(
          success: false,
          error: 'Login con Google no implementado aún',
        );
      } catch (e) {
        return ApiResponse<LoginResponse>(
          success: false,
          error: 'Error de conexión: $e',
        );
      }
    }

    // ===== MÉTODOS DE TOKEN =====
    Future<void> saveToken(String token) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    }

    Future<void> saveRefreshToken(String refreshToken) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_refresh_token', refreshToken);
    }

    Future<String?> getToken() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    }

    Future<String?> getRefreshToken() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_refresh_token');
    }

    Future<void> clearTokens() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_refresh_token');
      await prefs.remove('auth_user');
    }

    Future<bool> isAuthenticated() async {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    }

    // ===== MÉTODOS AUXILIARES =====
    String _formatFieldName(String fieldName) {
      final Map<String, String> fieldTranslations = {
        'email': 'Correo electrónico',
        'password': 'Contraseña',
        'nombre': 'Nombre',
        'apellido': 'Apellido',
        'telefono': 'Teléfono',
        'direccion': 'Dirección',
      };
      return fieldTranslations[fieldName] ?? fieldName;
    }

    // ===== MÉTODOS DE UI =====
    void showSuccessToast(String message) {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    }

    void showErrorToast(String message) {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Clase ApiResponse
  class ApiResponse<T> {
    final bool success;
    final T? data;
    final String? error;
    final String? message;

    ApiResponse({required this.success, this.data, this.error, this.message});
  }