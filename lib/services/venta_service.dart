import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/venta.dart';
import 'dart:math';

class VentasService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _ventasCollection = 'ventas';
  final String _detalleVentasCollection = 'detalle_ventas';
  final String _inventarioCollection = 'inventario';

  // Generar número de venta único
  String _generarNumeroVenta() {
    final now = DateTime.now();
    final random = Random();
    return 'V${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${random.nextInt(9999).toString().padLeft(4, '0')}';
  }

  // Obtener vendedor logueado
  Future<Vendedor> _getVendedorLogueado() async {
    final prefs = await SharedPreferences.getInstance();
    return Vendedor(
      id: prefs.getString('userId') ?? '',
      nombre: prefs.getString('nombre') ?? 'Usuario',
      usuario: prefs.getString('usuario') ?? 'user',
    );
  }

  // Obtener productos disponibles para venta
  Stream<List<ProductoInventario>> getProductosDisponibles() {
    return _firestore
        .collection(_inventarioCollection)
        .where('disponible', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ProductoInventario.fromMap(doc.id, data);
      }).toList();
    });
  }

  // Procesar venta completa
  Future<String> procesarVenta({
    required List<Map<String, dynamic>> productosSeleccionados,
    required String metodoPago,
    String? observaciones,
  }) async {
    final batch = _firestore.batch();
    
    try {
      // 1. Generar datos de la venta
      final numeroVenta = _generarNumeroVenta();
      final fechaVenta = DateTime.now();
      final vendedor = await _getVendedorLogueado();
      
      // 2. Calcular totales
      double subtotal = 0;
      int cantidadProductos = 0;
      
      for (var item in productosSeleccionados) {
        final producto = item['producto'] as ProductoInventario;
        final cantidad = item['cantidad'] as int;
        subtotal += producto.precio * cantidad;
        cantidadProductos += cantidad;
      }
      
      final isv = subtotal * 0.15;
      final total = subtotal + isv;
      
      // 3. Crear documento de venta
      final ventaRef = _firestore.collection(_ventasCollection).doc();
      final venta = Venta(
        id: ventaRef.id,
        numeroVenta: numeroVenta,
        fechaVenta: fechaVenta,
        vendedor: vendedor,
        metodoPago: metodoPago,
        subtotal: subtotal,
        isv: isv,
        total: total,
        estado: 'completada',
        observaciones: observaciones,
        cantidadProductos: cantidadProductos,
        fechaCreacion: fechaVenta,
      );
      
      batch.set(ventaRef, venta.toMap());
      
      // 4. Crear detalles de venta y actualizar inventario
      for (var item in productosSeleccionados) {
        final producto = item['producto'] as ProductoInventario;
        final cantidad = item['cantidad'] as int;
        
        // Crear detalle de venta
        final detalleRef = _firestore.collection(_detalleVentasCollection).doc();
        final detalle = DetalleVenta(
          id: detalleRef.id,
          ventaId: ventaRef.id,
          numeroVenta: numeroVenta,
          producto: ProductoVendido(
            inventarioId: producto.id,
            nombre: producto.nombre,
            imei: producto.imei,
          ),
          cantidad: cantidad,
          precioUnitario: producto.precio,
          subtotalProducto: producto.precio * cantidad,
          fechaVenta: fechaVenta,
          vendedor: vendedor.nombre,
        );
        
        batch.set(detalleRef, detalle.toMap());
        
        // Marcar producto como no disponible (vendido)
        final inventarioRef = _firestore.collection(_inventarioCollection).doc(producto.id);
        batch.update(inventarioRef, {
          'disponible': false,
          'fechaVenta': Timestamp.fromDate(fechaVenta),
          'vendidoPor': vendedor.nombre,
          'numeroVenta': numeroVenta,
          'fechaActualizacion': FieldValue.serverTimestamp(),
        });
      }
      
      // 5. Ejecutar todas las operaciones
      await batch.commit();
      
      print('✅ Venta procesada exitosamente: $numeroVenta');
      return ventaRef.id;
      
    } catch (e) {
      print('❌ Error al procesar venta: $e');
      throw Exception('Error al procesar la venta: $e');
    }
  }

  // Obtener ventas del día actual
  Stream<List<Venta>> getVentasHoy() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return _firestore
        .collection(_ventasCollection)
        .where('fechaVenta', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('fechaVenta', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('fechaVenta', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Venta.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Obtener todas las ventas (con paginación opcional)
  Stream<List<Venta>> getVentas({int? limit}) {
    Query query = _firestore
        .collection(_ventasCollection)
        .orderBy('fechaVenta', descending: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Venta.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Obtener detalles de una venta específica
  Future<List<DetalleVenta>> getDetallesVenta(String ventaId) async {
    try {
      final snapshot = await _firestore
          .collection(_detalleVentasCollection)
          .where('ventaId', isEqualTo: ventaId)
          .get();
      
      return snapshot.docs.map((doc) {
        return DetalleVenta.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      print('❌ Error al obtener detalles de venta: $e');
      throw Exception('Error al obtener detalles de venta: $e');
    }
  }

  // Obtener estadísticas de ventas
  Future<Map<String, dynamic>> getEstadisticasVentas() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      // Ventas de hoy
      final ventasHoySnapshot = await _firestore
          .collection(_ventasCollection)
          .where('fechaVenta', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('fechaVenta', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      // Total ventas del mes
      final startOfMonth = DateTime(today.year, today.month, 1);
      final ventasMesSnapshot = await _firestore
          .collection(_ventasCollection)
          .where('fechaVenta', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      double totalHoy = 0;
      double totalMes = 0;
      int cantidadVentasHoy = ventasHoySnapshot.docs.length;
      int cantidadVentasMes = ventasMesSnapshot.docs.length;

      // Calcular totales
      for (var doc in ventasHoySnapshot.docs) {
        totalHoy += (doc.data()['total'] ?? 0).toDouble();
      }

      for (var doc in ventasMesSnapshot.docs) {
        totalMes += (doc.data()['total'] ?? 0).toDouble();
      }

      return {
        'ventasHoy': cantidadVentasHoy,
        'totalHoy': totalHoy,
        'ventasMes': cantidadVentasMes,
        'totalMes': totalMes,
      };
    } catch (e) {
      print('❌ Error al obtener estadísticas: $e');
      return {
        'ventasHoy': 0,
        'totalHoy': 0.0,
        'ventasMes': 0,
        'totalMes': 0.0,
      };
    }
  }

  // Cancelar una venta (cambiar estado)
  Future<void> cancelarVenta(String ventaId, String motivo) async {
    final batch = _firestore.batch();
    
    try {
      // 1. Actualizar estado de la venta
      final ventaRef = _firestore.collection(_ventasCollection).doc(ventaId);
      batch.update(ventaRef, {
        'estado': 'cancelada',
        'motivoCancelacion': motivo,
        'fechaCancelacion': FieldValue.serverTimestamp(),
      });

      // 2. Obtener detalles de la venta para restaurar inventario
      final detalles = await getDetallesVenta(ventaId);
      
      // 3. Restaurar disponibilidad de productos
      for (var detalle in detalles) {
        final inventarioRef = _firestore
            .collection(_inventarioCollection)
            .doc(detalle.producto.inventarioId);
        
        batch.update(inventarioRef, {
          'disponible': true,
          'fechaVenta': FieldValue.delete(),
          'vendidoPor': FieldValue.delete(),
          'numeroVenta': FieldValue.delete(),
          'fechaActualizacion': FieldValue.serverTimestamp(),
        });
      }
      
      // 4. Ejecutar cambios
      await batch.commit();
      
      print('✅ Venta cancelada exitosamente: $ventaId');
    } catch (e) {
      print('❌ Error al cancelar venta: $e');
      throw Exception('Error al cancelar la venta: $e');
    }
  }
}