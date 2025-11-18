// lib/models/product_model.dart
class Product {
  final int id;
  final String sku;
  final String name;
  final String description;
  final double price;
  final String category;
  final String brand;
  final String imageUrl;
  final String estado;
  final DateTime fechaCreacion;
  final Inventario? inventario;

  Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.brand,
    required this.imageUrl,
    required this.estado,
    required this.fechaCreacion,
    this.inventario,
  });
  Product.empty()
      : id = 0,
        sku = '',
        name = 'Producto no disponible', // Un nombre descriptivo para placeholders
        description = '',
        price = 0.0,
        category = '',
        brand = '',
        imageUrl = '', // Puedes usar una URL de imagen de placeholder si tienes una
        estado = 'inactivo',
        fechaCreacion = DateTime.now(),
        inventario = null; // Los campos opci

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      sku: json['sku'] ?? '',
      name: json['nombre'] ?? '',
      description: json['descripcion'] ?? '',
      price: (json['precio'] ?? 0.0).toDouble(),
      category: json['categoria'] != null 
          ? (json['categoria'] is String ? json['categoria'] : json['categoria']['nombre_categoria'] ?? '')
          : '',
      brand: json['marca'] != null
          ? (json['marca'] is String ? json['marca'] : json['marca']['nombre_marca'] ?? '')
          : '',
      imageUrl: json['imagen_url'] ?? '',
      estado: json['estado'] ?? 'activo',
      fechaCreacion: DateTime.parse(json['fecha_creacion'] ?? DateTime.now().toString()),
      inventario: json['inventario'] != null ? Inventario.fromJson(json['inventario']) : null,
    );
  }

  // Helper methods
  bool get isActive => estado == 'activo';
  bool get isInactive => estado == 'inactivo';
  bool get isOutOfStock => estado == 'agotado';
  
  int get stock => inventario?.stockActual ?? 0;
  bool get hasStock => stock > 0;
  
  // Para compatibilidad con código existente
  double get rating => 4.5;
  int get reviewCount => 0;
}

class Inventario {
  final int id;
  final int stockActual;
  final int stockMinimo;
  final String ubicacionAlmacen;

  Inventario({
    required this.id,
    required this.stockActual,
    required this.stockMinimo,
    required this.ubicacionAlmacen,
  });

  factory Inventario.fromJson(Map<String, dynamic> json) {
    return Inventario(
      id: json['id'] ?? 0,
      stockActual: json['stock_actual'] ?? 0,
      stockMinimo: json['stock_minimo'] ?? 0,
      ubicacionAlmacen: json['ubicacion_almacen'] ?? '',
    );
  }
}

class Categoria {
  final int id;
  final String nombre;

  Categoria({
    required this.id,
    required this.nombre,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] ?? 0,
      nombre: json['nombre_categoria'] ?? '',
    );
  }
}

class Marca {
  final int id;
  final String nombre;

  Marca({
    required this.id,
    required this.nombre,
  });

  factory Marca.fromJson(Map<String, dynamic> json) {
    return Marca(
      id: json['id'] ?? 0,
      nombre: json['nombre_marca'] ?? '',
    );
  }
}