import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventario.dart';

class InventarioService {
  final CollectionReference _inventarioRef =
      FirebaseFirestore.instance.collection('inventario');

  Stream<List<Inventario>> getInventario() {
    return _inventarioRef
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return Inventario(
          id: doc.id,
          nombre: data['nombre'] ?? '',
          imei: data['imei'] ?? '',
          total: data['total'] is num ? (data['total'] as num).toInt() : 0,
          fecha: (data['fecha'] as Timestamp).toDate(),
        );
      }).toList();
    });
  }

 Future<void> guardarInventario(List<Inventario> inventario) async {
  final batch = FirebaseFirestore.instance.batch();

  for (var item in inventario) {
    final docRef = _inventarioRef.doc();
    final itemData = item.toMap();
    itemData['fecha'] = Timestamp.fromDate(item.fecha);
    itemData['disponible'] = true; 
    itemData['stock'] = 1; 

    batch.set(docRef, itemData);
  }

  await batch.commit();
}
  Future<void> eliminarItemInventario(String id) async {
    await _inventarioRef.doc(id).delete();
  }

  Future<List<Inventario>> buscarInventario({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? imei,
  }) async {
    Query query = _inventarioRef;

    if (fechaInicio != null) {
      query = query.where('fecha',
          isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio));
    }

    if (fechaFin != null) {
      query = query.where('fecha',
          isLessThanOrEqualTo: Timestamp.fromDate(fechaFin));
    }

    if (imei != null && imei.isNotEmpty) {
      query = query.where('imei', isEqualTo: imei);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return Inventario(
        id: doc.id,
        nombre: data['nombre'] ?? '',
        imei: data['imei'] ?? '',
        total: data['total'] is num ? (data['total'] as num).toInt() : 0,
        fecha: (data['fecha'] as Timestamp).toDate(),
      );
    }).toList();
  }
}