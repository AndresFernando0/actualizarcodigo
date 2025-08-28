import 'package:cloud_firestore/cloud_firestore.dart';

class Inventario {
  final String id;
  final String nombre;
  final String imei;
  final double precio; // Cambiado de int total a double precio
  final int stock;
  final bool disponible;
  final DateTime fecha;
  final DateTime? fechaActualizacion;
  final DateTime? fechaVenta;
  final String? vendidoPor;
  final String? numeroVenta;

  Inventario({
    required this.id,
    required this.nombre,
    required this.imei,
    required this.precio,
    this.stock = 1,
    this.disponible = true,
    required this.fecha,
    this.fechaActualizacion,
    this.fechaVenta,
    this.vendidoPor,
    this.numeroVenta,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'imei': imei,
      'precio': precio,
      'stock': stock,
      'disponible': disponible,
      'fecha': Timestamp.fromDate(fecha),
      'fechaActualizacion': FieldValue.serverTimestamp(),
      if (fechaVenta != null) 'fechaVenta': Timestamp.fromDate(fechaVenta!),
      if (vendidoPor != null) 'vendidoPor': vendidoPor,
      if (numeroVenta != null) 'numeroVenta': numeroVenta,
    };
  }

  factory Inventario.fromMap(String id, Map<String, dynamic> map) {
    return Inventario(
      id: id,
      nombre: map['nombre'] ?? '',
      imei: map['imei'] ?? '',
      precio: (map['precio'] ?? map['total'] ?? 0).toDouble(), // Compatibilidad con datos antiguos
      stock: map['stock'] ?? 1,
      disponible: map['disponible'] ?? true,
      fecha: (map['fecha'] as Timestamp).toDate(),
      fechaActualizacion: map['fechaActualizacion'] != null 
          ? (map['fechaActualizacion'] as Timestamp).toDate() 
          : null,
      fechaVenta: map['fechaVenta'] != null 
          ? (map['fechaVenta'] as Timestamp).toDate() 
          : null,
      vendidoPor: map['vendidoPor'],
      numeroVenta: map['numeroVenta'],
    );
  }

  // Método para convertir a ProductoInventario
  ProductoInventario toProductoInventario() {
    return ProductoInventario(
      id: id,
      nombre: nombre,
      imei: imei,
      precio: precio,
      stock: stock,
      disponible: disponible,
      fecha: fecha,
    );
  }
}

// Clase ProductoInventario mejorada
class ProductoInventario {
  final String id;
  final String nombre;
  final String imei;
  final double precio;
  final int stock;
  final bool disponible;
  final DateTime fecha;
  final DateTime? fechaActualizacion;
  final DateTime? fechaVenta;
  final String? vendidoPor;
  final String? numeroVenta;

  ProductoInventario({
    required this.id,
    required this.nombre,
    required this.imei,
    required this.precio,
    this.stock = 1,
    this.disponible = true,
    required this.fecha,
    this.fechaActualizacion,
    this.fechaVenta,
    this.vendidoPor,
    this.numeroVenta,
  });

  factory ProductoInventario.fromMap(String id, Map<String, dynamic> map) {
    return ProductoInventario(
      id: id,
      nombre: map['nombre'] ?? '',
      imei: map['imei'] ?? '',
      precio: (map['precio'] ?? map['total'] ?? 0).toDouble(),
      stock: map['stock'] ?? 1,
      disponible: map['disponible'] ?? true,
      fecha: (map['fecha'] as Timestamp).toDate(),
      fechaActualizacion: map['fechaActualizacion'] != null 
          ? (map['fechaActualizacion'] as Timestamp).toDate() 
          : null,
      fechaVenta: map['fechaVenta'] != null 
          ? (map['fechaVenta'] as Timestamp).toDate() 
          : null,
      vendidoPor: map['vendidoPor'],
      numeroVenta: map['numeroVenta'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'imei': imei,
      'precio': precio,
      'stock': stock,
      'disponible': disponible,
      'fecha': Timestamp.fromDate(fecha),
      'fechaActualizacion': FieldValue.serverTimestamp(),
      if (fechaVenta != null) 'fechaVenta': Timestamp.fromDate(fechaVenta!),
      if (vendidoPor != null) 'vendidoPor': vendidoPor,
      if (numeroVenta != null) 'numeroVenta': numeroVenta,
    };
  }
}