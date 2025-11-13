// lib/models/smartsales_models.dart

import 'package:flutter/foundation.dart';

@immutable
class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final bool isAdmin;
  final String? telefono;
  final String? direccion;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.isAdmin = false,
    this.telefono,
    this.direccion,
  });

  // Constructor `factory` para crear un User a partir de un mapa (JSON)
  // Esto es muy útil cuando recibes datos de una API.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'cliente', // Valor por defecto si es nulo
      isAdmin: json['isAdmin'] as bool? ?? false, // Valor por defecto si es nulo
      telefono: json['telefono'] as String?,
      direccion: json['direccion'] as String?,
    );
  }

  // Método para crear una copia del usuario, modificando algunos campos.
  // Es crucial para actualizar el estado del perfil de forma inmutable.
  User copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    bool? isAdmin,
    String? telefono,
    String? direccion,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      isAdmin: isAdmin ?? this.isAdmin,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
    );
  }
}
