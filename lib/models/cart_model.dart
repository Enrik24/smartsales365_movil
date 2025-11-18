// lib/models/cart_model.dart

import 'product_model.dart';
import 'package:uuid/uuid.dart'; // Ideal para generar IDs únicos si es necesario

class Cart {
  final dynamic id; // Puede ser int de la BD o String si es nuevo
  final int? usuario;
  final DateTime fechaUltimaActualizacion;
  final List<DetalleCarrito> items;

  // El total ahora es un getter para que siempre esté calculado y sea correcto.
  double get total {
    return items.fold(0, (sum, item) => sum + item.subtotal);
  }

  // Constructor principal mejorado con parámetros opcionales.
  // Permite crear un carrito vacío simplemente con `Cart()`.
  Cart({
    this.id,
    this.usuario,
    DateTime? fechaUltimaActualizacion,
    List<DetalleCarrito>? items,
  })  : this.fechaUltimaActualizacion = fechaUltimaActualizacion ?? DateTime.now(),
        this.items = items ?? [];

  factory Cart.fromJson(Map<String, dynamic> json) {
    var itemsList = (json['items'] as List? ?? [])
        .map((item) => DetalleCarrito.fromJson(item as Map<String, dynamic>))
        .toList();

    return Cart(
      id: json['id'],
      usuario: json['usuario'] as int?,
      fechaUltimaActualizacion: json['fecha_ultima_actualizacion'] != null
          ? DateTime.parse(json['fecha_ultima_actualizacion'])
          : DateTime.now(),
      items: itemsList,
    );
  }

  // --> MÉTODO CORREGIDO PARA USAR INMUTABILIDAD <--
  void updateQuantity(int productId, int newQuantity) {
    final itemIndex = items.indexWhere((item) => item.producto.id == productId);

    if (itemIndex != -1) {
      final oldItem = items[itemIndex];
      // Si la nueva cantidad es cero o menos, eliminamos el producto.
      if (newQuantity <= 0) {
        removeItem(productId);
      } else {
        // Creamos una nueva instancia del item y la reemplazamos en la lista.
        items[itemIndex] = oldItem.copyWith(cantidad: newQuantity);
      }
    } else {
      print('Producto con id $productId no encontrado en el carrito.');
    }
  }

  void removeItem(int productId) {
    items.removeWhere((item) => item.producto.id == productId);
  }

  void clear() {
    items.clear();
  }
}

class DetalleCarrito {
  final dynamic id;
  final Product producto;
  // Estos campos se hacen 'final' para promover la inmutabilidad.
  final int cantidad;
  final double subtotal;

  // Constructor mejorado con parámetros opcionales.
  DetalleCarrito({
    this.id,
    required this.producto,
    this.cantidad = 1, // Por defecto la cantidad es 1
  }) : this.subtotal = producto.price * (cantidad > 0 ? cantidad : 1);

  factory DetalleCarrito.fromJson(Map<String, dynamic> json) {
    // Asegura que 'producto' o 'producto_detalle' no sea nulo antes de procesar
    final productJson = json['producto_detalle'] ?? json['producto'];
    if (productJson == null) {
      throw FormatException("El DetalleCarrito JSON no contiene un producto válido.");
    }

    return DetalleCarrito(
      id: json['id'],
      producto: Product.fromJson(productJson as Map<String, dynamic>),
      cantidad: (json['cantidad'] as int?) ?? 1,
    );
  }

  // --> MÉTODO AÑADIDO PARA FACILITAR LA INMUTABILIDAD <--
  /// Crea una copia de esta instancia de DetalleCarrito,
  /// pero reemplazando los campos proporcionados.
  DetalleCarrito copyWith({
    dynamic id,
    Product? producto,
    int? cantidad,
  }) {
    return DetalleCarrito(
      id: id ?? this.id,
      producto: producto ?? this.producto,
      cantidad: cantidad ?? this.cantidad,
    );
  }
}
