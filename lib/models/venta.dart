import 'package:cloud_firestore/cloud_firestore.dart';

class Venta {
  final String id;
  final String numeroVenta;
  final DateTime fechaVenta;
  final Vendedor vendedor;
  final String metodoPago;
  final double subtotal;
  final double isv;
  final double total;
  final String estado;
  final String? observaciones;
  final int cantidadProductos;
  final DateTime fechaCreacion;

  Venta({
    required this.id,
    required this.numeroVenta,
    required this.fechaVenta,
    required this.vendedor,
    required this.metodoPago,
    required this.subtotal,
    required this.isv,
    required this.total,
    this.estado = 'completada',
    this.observaciones,
    required this.cantidadProductos,
    required this.fechaCreacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'numeroVenta': numeroVenta,
      'fechaVenta': Timestamp.fromDate(fechaVenta),
      'vendedor': vendedor.toMap(),
      'metodoPago': metodoPago,
      'subtotal': subtotal,
      'isv': isv,
      'total': total,
      'estado': estado,
      'observaciones': observaciones,
      'cantidadProductos': cantidadProductos,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    };
  }

  factory Venta.fromMap(String id, Map<String, dynamic> map) {
    return Venta(
      id: id,
      numeroVenta: map['numeroVenta'] ?? '',
      fechaVenta: (map['fechaVenta'] as Timestamp).toDate(),
      vendedor: Vendedor.fromMap(map['vendedor'] ?? {}),
      metodoPago: map['metodoPago'] ?? '',
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      isv: (map['isv'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      estado: map['estado'] ?? 'completada',
      observaciones: map['observaciones'],
      cantidadProductos: map['cantidadProductos'] ?? 0,
      fechaCreacion: (map['fechaCreacion'] as Timestamp).toDate(),
    );
  }
}

class Vendedor {
  final String id;
  final String nombre;
  final String usuario;

  Vendedor({
    required this.id,
    required this.nombre,
    required this.usuario,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'usuario': usuario,
    };
  }

  factory Vendedor.fromMap(Map<String, dynamic> map) {
    return Vendedor(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      usuario: map['usuario'] ?? '',
    );
  }
}

class DetalleVenta {
  final String id;
  final String ventaId;
  final String numeroVenta;
  final ProductoVendido producto;
  final int cantidad;
  final double precioUnitario;
  final double subtotalProducto;
  final DateTime fechaVenta;
  final String vendedor;

  DetalleVenta({
    required this.id,
    required this.ventaId,
    required this.numeroVenta,
    required this.producto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotalProducto,
    required this.fechaVenta,
    required this.vendedor,
  });

  Map<String, dynamic> toMap() {
    return {
      'ventaId': ventaId,
      'numeroVenta': numeroVenta,
      'producto': producto.toMap(),
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
      'subtotalProducto': subtotalProducto,
      'fechaVenta': Timestamp.fromDate(fechaVenta),
      'vendedor': vendedor,
    };
  }

  factory DetalleVenta.fromMap(String id, Map<String, dynamic> map) {
    return DetalleVenta(
      id: id,
      ventaId: map['ventaId'] ?? '',
      numeroVenta: map['numeroVenta'] ?? '',
      producto: ProductoVendido.fromMap(map['producto'] ?? {}),
      cantidad: map['cantidad'] ?? 0,
      precioUnitario: (map['precioUnitario'] ?? 0).toDouble(),
      subtotalProducto: (map['subtotalProducto'] ?? 0).toDouble(),
      fechaVenta: (map['fechaVenta'] as Timestamp).toDate(),
      vendedor: map['vendedor'] ?? '',
    );
  }
}

class ProductoVendido {
  final String inventarioId;
  final String nombre;
  final String imei;

  ProductoVendido({
    required this.inventarioId,
    required this.nombre,
    required this.imei,
  });

  Map<String, dynamic> toMap() {
    return {
      'inventarioId': inventarioId,
      'nombre': nombre,
      'imei': imei,
    };
  }

  factory ProductoVendido.fromMap(Map<String, dynamic> map) {
    return ProductoVendido(
      inventarioId: map['inventarioId'] ?? '',
      nombre: map['nombre'] ?? '',
      imei: map['imei'] ?? '',
    );
  }
}

// Modelo para productos en inventario (actualizado)
class ProductoInventario {
  final String id;
  final String nombre;
  final String imei;
  final double precio;
  final int stock;
  final bool disponible;
  final DateTime fecha;

  ProductoInventario({
    required this.id,
    required this.nombre,
    required this.imei,
    required this.precio,
    required this.stock,
    required this.disponible,
    required this.fecha,
  });

  factory ProductoInventario.fromMap(String id, Map<String, dynamic> map) {
    return ProductoInventario(
      id: id,
      nombre: map['nombre'] ?? '',
      imei: map['imei'] ?? '',
      precio: (map['precio'] ?? 0).toDouble(),
      stock: map['stock'] ?? 1,
      disponible: map['disponible'] ?? true,
      fecha: (map['fecha'] as Timestamp).toDate(),
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
    };
  }
}