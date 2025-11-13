import 'package:smartsales365_movil/models/product_model.dart';

class Order {
  final int id;
  final int usuario;
  final DateTime fechaPedido;
  final double montoTotal;
  final String estadoPedido;
  final String direccionEnvio;
  final String? direccionFacturacion;
  final String? numeroSeguimiento;
  final List<DetallePedido> detalles;
  final String? usuarioNombre;

  Order({
    required this.id,
    required this.usuario,
    required this.fechaPedido,
    required this.montoTotal,
    required this.estadoPedido,
    required this.direccionEnvio,
    this.direccionFacturacion,
    this.numeroSeguimiento,
    required this.detalles,
    this.usuarioNombre,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      usuario: json['usuario'],
      fechaPedido: DateTime.parse(json['fecha_pedido']),
      montoTotal: (json['monto_total'] as num).toDouble(),
      estadoPedido: json['estado_pedido'],
      direccionEnvio: json['direccion_envio'],
      direccionFacturacion: json['direccion_facturacion'],
      numeroSeguimiento: json['numero_seguimiento'],
      detalles: (json['detalles'] as List? ?? [])
          .map((item) => DetallePedido.fromJson(item))
          .toList(),
      usuarioNombre: json['usuario_nombre'],
    );
  }
}

class DetallePedido {
  final int id;
  final int pedido;
  final Product producto;
  final int cantidad;
  final double precioUnitarioEnElMomento;
  final double subtotal;
  final Product? productoDetalle;

  DetallePedido({
    required this.id,
    required this.pedido,
    required this.producto,
    required this.cantidad,
    required this.precioUnitarioEnElMomento,
    required this.subtotal,
    this.productoDetalle,
  });

  factory DetallePedido.fromJson(Map<String, dynamic> json) {
    return DetallePedido(
      id: json['id'],
      pedido: json['pedido'],
      producto: Product.fromJson(json['producto']),
      cantidad: json['cantidad'],
      precioUnitarioEnElMomento: (json['precio_unitario_en_el_momento'] as num).toDouble(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      productoDetalle: json['producto_detalle'] != null 
          ? Product.fromJson(json['producto_detalle'])
          : null,
    );
  }
}