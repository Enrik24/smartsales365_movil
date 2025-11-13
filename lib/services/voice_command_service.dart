import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../utils/ip_detection.dart';
import 'auth_service.dart';

class VoiceCommandService {
  static final VoiceCommandService _instance = VoiceCommandService._internal();
  factory VoiceCommandService() => _instance;
  VoiceCommandService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final AuthService _authService = AuthService();
  bool _isInitialized = false;

  Future<void> initialize() async {
    _isInitialized = await _speech.initialize();
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Procesar comando con el backend
  Future<VoiceCommandResponse> processVoiceCommand(String transcript) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/comandos-voz/procesar/');

      final body = {
        'transcript': transcript,
        'contexto': 'mobile_app',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return VoiceCommandResponse.fromJson(responseData);
      } else {
        return VoiceCommandResponse(
          success: false,
          error: 'Error del servidor: ${response.statusCode}',
        );
      }
    } catch (e) {
      return VoiceCommandResponse(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  // Procesar directamente con endpoint OpenAI
  Future<VoiceCommandResponse> processWithOpenAI(String transcript) async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/comandos-voz/procesar-openai/');

      final body = {
        'command': transcript,
        'context': 'mobile_ecommerce',
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return VoiceCommandResponse.fromJson(responseData);
      } else {
        // Fallback al procesamiento regular
        return await processVoiceCommand(transcript);
      }
    } catch (e) {
      // Fallback a procesamiento local
      return _processLocally(transcript);
    }
  }

  // Procesamiento local mejorado
  VoiceCommandResponse _processLocally(String transcript) {
    final command = transcript.toLowerCase();
    
    // Comandos para reportes
    if (command.contains('carrito') || command.contains('compras')) {
      return VoiceCommandResponse(
        success: true,
        action: 'navigate',
        target: '/cart',
        message: 'Abriendo tu carrito de compras',
        confidence: 0.8,
      );
    } else if (command.contains('producto') || command.contains('buscar')) {
      return VoiceCommandResponse(
        success: true,
        action: 'search',
        target: '/catalog',
        message: 'Buscando productos',
        confidence: 0.7,
      );
    } else if (command.contains('pedido') || command.contains('historial')) {
      return VoiceCommandResponse(
        success: true,
        action: 'navigate',
        target: '/order-history',
        message: 'Mostrando tu historial de pedidos',
        confidence: 0.9,
      );
    } else if (command.contains('reporte') || command.contains('ventas')) {
      return VoiceCommandResponse(
        success: true,
        action: 'report',
        target: '/reports',
        message: 'Preparando reporte de ventas',
        confidence: 0.8,
        parameters: {'tipo_reporte': 'ventas'},
      );
    } else if (command.contains('cliente') || command.contains('usuarios')) {
      return VoiceCommandResponse(
        success: true,
        action: 'report',
        target: '/reports',
        message: 'Generando reporte de clientes',
        confidence: 0.8,
        parameters: {'tipo_reporte': 'clientes'},
      );
    } else if (command.contains('stock') || command.contains('inventario')) {
      return VoiceCommandResponse(
        success: true,
        action: 'report',
        target: '/reports',
        message: 'Analizando niveles de inventario',
        confidence: 0.8,
        parameters: {'tipo_reporte': 'inventario'},
      );
    } else {
      return VoiceCommandResponse(
        success: false,
        error: 'No entendí el comando. Intenta decir: "Reporte de ventas", "Ver mi carrito" o "Buscar productos"',
      );
    }
  }

  // CORREGIDO: Escuchar comando de voz
  Future<VoiceListeningResult> listenForCommand() async {
    if (!_isInitialized) {
      await initialize();
    }

    final result = VoiceListeningResult();
    
    try {
      bool isAvailable = await _speech.initialize();
      
      if (!isAvailable) {
        result.error = 'El reconocimiento de voz no está disponible';
        return result;
      }

      // CORRECCIÓN: Usar stt.SpeechRecognitionResult en lugar de SpeechRecognitionResult
      await _speech.listen(
        onResult: (stt.SpeechRecognitionResult recognition) {
          if (recognition.finalResult) {
            result.transcript = recognition.recognizedWords;
            result.isFinal = true;
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        cancelOnError: true,
      );

      // Esperar hasta que se complete el reconocimiento
      await Future.delayed(const Duration(seconds: 10));
      
      if (!result.isFinal && result.transcript.isEmpty) {
        result.error = 'No se detectó ningún comando';
      }

    } catch (e) {
      result.error = 'Error durante el reconocimiento: $e';
    } finally {
      await _speech.stop();
    }

    return result;
  }

  // Obtener comandos frecuentes del backend
  Future<List<SuggestedCommand>> getSuggestedCommands() async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/comandos-voz/sugerencias/');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<SuggestedCommand> suggestions = [];

        if (responseData is List) {
          suggestions = responseData.map((item) => SuggestedCommand.fromJson(item)).toList();
        }

        return suggestions;
      } else {
        return _getDefaultSuggestedCommands();
      }
    } catch (e) {
      return _getDefaultSuggestedCommands();
    }
  }

  List<SuggestedCommand> _getDefaultSuggestedCommands() {
    return [
      SuggestedCommand(
        command: 'Generar reporte de ventas del mes',
        description: 'Crea un reporte de ventas del mes actual',
        category: 'reportes',
      ),
      SuggestedCommand(
        command: 'Mostrar productos con bajo stock',
        description: 'Lista productos con stock por debajo del mínimo',
        category: 'inventario',
      ),
      SuggestedCommand(
        command: 'Reporte de clientes nuevos',
        description: 'Genera reporte de clientes registrados recientemente',
        category: 'reportes',
      ),
      SuggestedCommand(
        command: 'Buscar productos en oferta',
        description: 'Muestra productos con descuentos especiales',
        category: 'busqueda',
      ),
      SuggestedCommand(
        command: 'Ver mi carrito de compras',
        description: 'Abre tu carrito con los productos agregados',
        category: 'navegacion',
      ),
      SuggestedCommand(
        command: 'Seguir mi último pedido',
        description: 'Consulta el estado de tu pedido más reciente',
        category: 'pedidos',
      ),
    ];
  }

  // Obtener historial de comandos del backend
  Future<List<VoiceCommandHistory>> getCommandHistory() async {
    try {
      final baseUrl = await IPDetection.getBaseUrl();
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/comandos-voz/voz/historial/');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<VoiceCommandHistory> history = [];

        if (responseData is List) {
          history = responseData.map((item) => VoiceCommandHistory.fromJson(item)).toList();
        }

        return history;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}

class VoiceCommandResponse {
  final bool success;
  final String? action;
  final String? target;
  final Map<String, dynamic>? parameters;
  final String? message;
  final String? error;
  final double confidence;
  final String? intencion;
  final String? tipoComando;

  VoiceCommandResponse({
    required this.success,
    this.action,
    this.target,
    this.parameters,
    this.message,
    this.error,
    this.confidence = 1.0,
    this.intencion,
    this.tipoComando,
  });

  factory VoiceCommandResponse.fromJson(Map<String, dynamic> json) {
    return VoiceCommandResponse(
      success: json['exito'] ?? json['success'] ?? false,
      action: _mapActionFromIntent(json['intencion'] ?? json['action']),
      target: json['target'] ?? _mapTargetFromIntent(json['intencion']),
      parameters: json['parametros'] != null 
          ? Map<String, dynamic>.from(json['parametros'])
          : json['parameters'] != null
            ? Map<String, dynamic>.from(json['parameters'])
            : null,
      message: json['respuesta'] != null 
          ? (json['respuesta']['mensaje'] ?? json['respuesta']['message'])
          : json['message'],
      error: json['error'],
      confidence: (json['confianza'] ?? json['confidence'] ?? 1.0).toDouble(),
      intencion: json['intencion'],
      tipoComando: json['tipo_comando'],
    );
  }

  static String? _mapActionFromIntent(String? intent) {
    if (intent == null) return null;
    
    final actionMap = {
      'reporte_ventas': 'report',
      'reporte_clientes': 'report',
      'reporte_productos': 'report',
      'reporte_inventario': 'report',
      'busqueda_productos': 'search',
      'navegacion': 'navigate',
    };
    
    return actionMap[intent] ?? 'execute';
  }

  static String? _mapTargetFromIntent(String? intent) {
    if (intent == null) return null;
    
    final targetMap = {
      'reporte_ventas': '/reports',
      'reporte_clientes': '/reports',
      'reporte_productos': '/reports',
      'reporte_inventario': '/reports',
      'busqueda_productos': '/catalog',
    };
    
    return targetMap[intent];
  }
}

class VoiceListeningResult {
  String transcript = '';
  bool isFinal = false;
  String? error;
}

class VoiceCommandHistory {
  final int id;
  final String transcript;
  final String? processedText;
  final String commandType;
  final DateTime executionDate;
  final bool success;

  VoiceCommandHistory({
    required this.id,
    required this.transcript,
    this.processedText,
    required this.commandType,
    required this.executionDate,
    required this.success,
  });

  factory VoiceCommandHistory.fromJson(Map<String, dynamic> json) {
    return VoiceCommandHistory(
      id: json['id'],
      transcript: json['transcript_original'] ?? json['texto_original'] ?? '',
      processedText: json['transcript_procesado'] ?? json['texto_procesado'],
      commandType: json['tipo_comando'] ?? 'voice',
      executionDate: DateTime.parse(json['fecha_ejecucion']),
      success: json['exito'] ?? true,
    );
  }
}

class SuggestedCommand {
  final String command;
  final String description;
  final String category;

  SuggestedCommand({
    required this.command,
    required this.description,
    required this.category,
  });

  factory SuggestedCommand.fromJson(Map<String, dynamic> json) {
    return SuggestedCommand(
      command: json['comando'] ?? json['command'] ?? '',
      description: json['descripcion'] ?? json['description'] ?? '',
      category: json['categoria'] ?? json['category'] ?? 'general',
    );
  }
}