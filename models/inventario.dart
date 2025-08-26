import 'package:cloud_firestore/cloud_firestore.dart';

class Inventario {
  final String id;
  final String nombre;
  final String imei;
  final int total;
  final DateTime fecha;

  Inventario({
    required this.id,
    required this.nombre,
    required this.imei,
    required this.total,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'imei': imei,
      'total': total,
      'fecha': Timestamp.fromDate(fecha),
    };
  }

  factory Inventario.fromMap(String id, Map<String, dynamic> map) {
    return Inventario(
      id: id,
      nombre: map['nombre'] ?? '',
      imei: map['imei'] ?? '',
      total: map['total'] ?? 0, 
      fecha: (map['fecha'] as Timestamp).toDate(),
    );
  }
}