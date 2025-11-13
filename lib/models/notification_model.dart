// lib/models/notification_model.dart
class AppNotification {
  final int id;
  final String tipo;
  final String titulo;
  final String mensaje;
  final DateTime fechaCreacion;
  final DateTime? fechaEnvio;
  final String estado;
  final Map<String, dynamic>? datosAdicionales;

  AppNotification({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.fechaCreacion,
    this.fechaEnvio,
    required this.estado,
    this.datosAdicionales,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? 0,
      tipo: json['tipo'] ?? 'sistema',
      titulo: json['titulo'] ?? '',
      mensaje: json['mensaje'] ?? '',
      fechaCreacion: DateTime.parse(json['fecha_creacion'] ?? DateTime.now().toString()),
      fechaEnvio: json['fecha_envio'] != null ? DateTime.parse(json['fecha_envio']) : null,
      estado: json['estado'] ?? 'pendiente',
      datosAdicionales: json['datos_adicionales'],
    );
  }

  bool get isRead => estado == 'leida';
  bool get isPending => estado == 'pendiente';
  bool get isSent => estado == 'enviada';
  bool get hasError => estado == 'error';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'titulo': titulo,
      'mensaje': mensaje,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_envio': fechaEnvio?.toIso8601String(),
      'estado': estado,
      'datos_adicionales': datosAdicionales,
    };
  }
}