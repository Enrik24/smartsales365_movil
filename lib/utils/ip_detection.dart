import 'dart:io';

/// 🧠 Clase para gestionar la detección del entorno y la URL base del backend
class IPDetection {
  // ================================
  // 🔧 CONFIGURACIONES DISPONIBLES
  // ================================

  // 1️⃣ Backend local en emulador Android (usa 10.0.2.2)
  static const String LOCAL_ANDROID = "http://10.0.2.2:8000";

  // 2️⃣ Backend local en dispositivo físico (cambia por tu IP local)
  // 👉 Para obtenerla ejecuta `ipconfig` en Windows o `ifconfig` en Linux/Mac
  static const String LOCAL_DEVICE = "http://192.168.1.100:8000";

  // 3️⃣ Backend en la nube (producción)
  // 👉 Cambia esto cuando despliegues tu backend en AWS / Render / etc.
  static const String CLOUD_HOST = "https://api.smartsales365.com";

  // ====================================
  // ⚙️ CONTROL DEL ENTORNO ACTUAL
  // ====================================
  //
  // Puedes cambiar manualmente el entorno aquí:
  // Opciones: "development", "device", "production"
  static const String ENVIRONMENT = "development";

  // Cache interno para evitar recomputar la URL
  static String? _cachedBaseUrl;

  /// Devuelve la URL base del backend según el entorno actual
  static Future<String> getBaseUrl() async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;

    switch (ENVIRONMENT) {
      case "development":
        _cachedBaseUrl = LOCAL_ANDROID;
        break;
      case "device":
        _cachedBaseUrl = LOCAL_DEVICE;
        break;
      case "production":
        _cachedBaseUrl = CLOUD_HOST;
        break;
      default:
        _cachedBaseUrl = LOCAL_ANDROID;
    }

    return _cachedBaseUrl!;
  }

  /// Devuelve información sobre el entorno actual
  static Future<Map<String, dynamic>> getEnvironmentInfo() async {
    final baseUrl = await getBaseUrl();
    final isCloud = baseUrl.contains('https');
    final isLocal = baseUrl.contains('10.0.2.2') || baseUrl.contains('192.168.');

    return {
      'baseUrl': baseUrl,
      'isCloud': isCloud,
      'isLocal': isLocal,
      'platform': Platform.operatingSystem,
      'environment': ENVIRONMENT,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Limpia la caché (útil si cambias el entorno en tiempo de ejecución)
  static void clearCache() {
    _cachedBaseUrl = null;
  }
}
