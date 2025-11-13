import 'product_model.dart';
class Cart {
  final int id;
  final int usuario;
  final DateTime fechaUltimaActualizacion;
  final List<DetalleCarrito> items;
  final double total;

  Cart({
    required this.id,
    required this.usuario,
    required this.fechaUltimaActualizacion,
    required this.items,
    required this.total,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'],
      usuario: json['usuario'],
      fechaUltimaActualizacion: DateTime.parse(json['fecha_ultima_actualizacion']),
      items: (json['items'] as List)
          .map((item) => DetalleCarrito.fromJson(item))
          .toList(),
      total: (json['total'] as num).toDouble(),
    );
  }

  void updateQuantity(int productId, int newQuantity) {
    final item = items.firstWhere((item) => item.producto.id == productId);
    item.cantidad = newQuantity;
  }

  void removeItem(int productId) {
    items.removeWhere((item) => item.producto.id == productId);
  }

  void clear() {
    items.clear();
  }

  double get totalAmount {
    return items.fold(0, (sum, item) => sum + (item.producto.price * item.cantidad));
  }
}

class DetalleCarrito {
  int id;
  final Product producto;
  int cantidad;
  double subtotal;

  DetalleCarrito({
    required this.id,
    required this.producto,
    required this.cantidad,
    required this.subtotal,
  });

  factory DetalleCarrito.fromJson(Map<String, dynamic> json) {
    return DetalleCarrito(
      id: json['id'],
      producto: Product.fromJson(json['producto_detalle'] ?? json['producto']),
      cantidad: json['cantidad'],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}