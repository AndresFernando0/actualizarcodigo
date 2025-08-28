import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventario.dart';

class InventarioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'inventario';

  // Obtener inventario completo en tiempo real
  Stream<List<Inventario>> getInventario() {
    return _firestore
        .collection(_collectionName)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Inventario.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Obtener solo productos disponibles para venta
  Stream<List<Inventario>> getProductosDisponibles() {
    return _firestore
        .collection(_collectionName)
        .where('disponible', isEqualTo: true)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Inventario.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Guardar múltiples productos de inventario
  Future<void> guardarInventario(List<Inventario> productos) async {
    final batch = _firestore.batch();
    
    try {
      print('🔄 Guardando ${productos.length} productos en inventario...');
      
      for (final producto in productos) {
        // Validaciones
        if (producto.nombre.isEmpty) {
          throw Exception('El nombre del producto no puede estar vacío');
        }
        
        if (producto.precio <= 0) {
          throw Exception('El precio debe ser mayor a 0');
        }

        // Verificar si el IMEI ya existe (solo si no está vacío)
        if (producto.imei.isNotEmpty) {
          final existeIMEI = await _verificarIMEIExiste(producto.imei, producto.id);
          if (existeIMEI) {
            throw Exception('Ya existe un producto con el IMEI: ${producto.imei}');
          }
        }
        
        final docRef = _firestore.collection(_collectionName).doc();
        final productoParaGuardar = Inventario(
          id: docRef.id,
          nombre: producto.nombre.trim(),
          imei: producto.imei.trim(),
          precio: producto.precio,
          stock: producto.stock,
          disponible: true,
          fecha: producto.fecha,
        );
        
        batch.set(docRef, productoParaGuardar.toMap());
        print('✅ Producto preparado para guardar: ${productoParaGuardar.nombre} - L. ${productoParaGuardar.precio}');
      }
      
      await batch.commit();
      print('🎉 ¡${productos.length} productos guardados exitosamente en el inventario!');
      
    } catch (e) {
      print('❌ Error en guardarInventario: $e');
      throw Exception('Error al guardar inventario: $e');
    }
  }

  // Guardar un solo producto
  Future<String> guardarProductoIndividual(Inventario producto) async {
    try {
      // Validaciones
      if (producto.nombre.isEmpty) {
        throw Exception('El nombre del producto no puede estar vacío');
      }
      
      if (producto.precio <= 0) {
        throw Exception('El precio debe ser mayor a 0');
      }

      // Verificar si el IMEI ya existe (solo si no está vacío)
      if (producto.imei.isNotEmpty) {
        final existeIMEI = await _verificarIMEIExiste(producto.imei, producto.id);
        if (existeIMEI) {
          throw Exception('Ya existe un producto con el IMEI: ${producto.imei}');
        }
      }

      final docRef = _firestore.collection(_collectionName).doc();
      final productoParaGuardar = Inventario(
        id: docRef.id,
        nombre: producto.nombre.trim(),
        imei: producto.imei.trim(),
        precio: producto.precio,
        stock: producto.stock,
        disponible: true,
        fecha: DateTime.now(),
      );

      await docRef.set(productoParaGuardar.toMap());
      print('✅ Producto individual guardado: ${productoParaGuardar.nombre}');
      
      return docRef.id;
    } catch (e) {
      print('❌ Error al guardar producto individual: $e');
      throw Exception('Error al guardar producto: $e');
    }
  }

  // Actualizar producto existente
  Future<void> actualizarProducto(String id, Inventario producto) async {
    try {
      // Validaciones
      if (producto.nombre.isEmpty) {
        throw Exception('El nombre del producto no puede estar vacío');
      }
      
      if (producto.precio <= 0) {
        throw Exception('El precio debe ser mayor a 0');
      }

      // Verificar si el IMEI ya existe en otro producto (solo si no está vacío)
      if (producto.imei.isNotEmpty) {
        final existeIMEI = await _verificarIMEIExiste(producto.imei, id);
        if (existeIMEI) {
          throw Exception('Ya existe otro producto con el IMEI: ${producto.imei}');
        }
      }

      final productoActualizado = Inventario(
        id: id,
        nombre: producto.nombre.trim(),
        imei: producto.imei.trim(),
        precio: producto.precio,
        stock: producto.stock,
        disponible: producto.disponible,
        fecha: producto.fecha,
        fechaVenta: producto.fechaVenta,
        vendidoPor: producto.vendidoPor,
        numeroVenta: producto.numeroVenta,
      );

      await _firestore.collection(_collectionName)
          .doc(id)
          .update(productoActualizado.toMap());
          
      print('✅ Producto actualizado: ${producto.nombre}');
    } catch (e) {
      print('❌ Error al actualizar producto: $e');
      throw Exception('Error al actualizar producto: $e');
    }
  }

  // Marcar producto como vendido
  Future<void> marcarComoVendido({
    required String productoId,
    required String numeroVenta,
    required String vendidoPor,
    required DateTime fechaVenta,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(productoId).update({
        'disponible': false,
        'fechaVenta': Timestamp.fromDate(fechaVenta),
        'vendidoPor': vendidoPor,
        'numeroVenta': numeroVenta,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
      
      print('✅ Producto marcado como vendido: $productoId');
    } catch (e) {
      print('❌ Error al marcar producto como vendido: $e');
      throw Exception('Error al marcar producto como vendido: $e');
    }
  }

  // Restaurar disponibilidad de producto (para cancelación de venta)
  Future<void> restaurarDisponibilidad(String productoId) async {
    try {
      await _firestore.collection(_collectionName).doc(productoId).update({
        'disponible': true,
        'fechaVenta': FieldValue.delete(),
        'vendidoPor': FieldValue.delete(),
        'numeroVenta': FieldValue.delete(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
      
      print('✅ Disponibilidad restaurada para producto: $productoId');
    } catch (e) {
      print('❌ Error al restaurar disponibilidad: $e');
      throw Exception('Error al restaurar disponibilidad: $e');
    }
  }

  // Eliminar producto del inventario
  Future<void> eliminarItemInventario(String id) async {
    try {
      // Verificar si el producto existe
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      if (!doc.exists) {
        throw Exception('El producto no existe');
      }

      // Obtener datos del producto para logging
      final producto = Inventario.fromMap(doc.id, doc.data()!);
      
      // Eliminar el documento
      await _firestore.collection(_collectionName).doc(id).delete();
      
      print('🗑️ Producto eliminado del inventario: ${producto.nombre}');
    } catch (e) {
      print('❌ Error al eliminar producto: $e');
      throw Exception('Error al eliminar producto: $e');
    }
  }

  // Obtener producto por ID
  Future<Inventario?> obtenerProductoPorId(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      
      if (doc.exists) {
        return Inventario.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener producto por ID: $e');
      throw Exception('Error al obtener producto: $e');
    }
  }

  // Buscar productos por nombre o IMEI
  Future<List<Inventario>> buscarProductos(String termino) async {
    try {
      if (termino.isEmpty) return [];

      final terminoLower = termino.toLowerCase();
      
      // Obtener todos los productos y filtrar localmente
      // (Firebase no soporta búsqueda de texto complejo directamente)
      final snapshot = await _firestore.collection(_collectionName).get();
      
      final productos = snapshot.docs
          .map((doc) => Inventario.fromMap(doc.id, doc.data()))
          .where((producto) =>
              producto.nombre.toLowerCase().contains(terminoLower) ||
              producto.imei.contains(termino))
          .toList();

      return productos;
    } catch (e) {
      print('❌ Error al buscar productos: $e');
      throw Exception('Error al buscar productos: $e');
    }
  }

  // Obtener estadísticas del inventario
  Future<Map<String, dynamic>> getEstadisticasInventario() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      
      int totalProductos = snapshot.docs.length;
      int disponibles = 0;
      int vendidos = 0;
      double valorTotalDisponible = 0;
      double valorTotalVendido = 0;

      for (var doc in snapshot.docs) {
        final producto = Inventario.fromMap(doc.id, doc.data());
        
        if (producto.disponible) {
          disponibles++;
          valorTotalDisponible += producto.precio;
        } else {
          vendidos++;
          valorTotalVendido += producto.precio;
        }
      }

      return {
        'totalProductos': totalProductos,
        'disponibles': disponibles,
        'vendidos': vendidos,
        'valorTotalDisponible': valorTotalDisponible,
        'valorTotalVendido': valorTotalVendido,
      };
    } catch (e) {
      print('❌ Error al obtener estadísticas: $e');
      return {
        'totalProductos': 0,
        'disponibles': 0,
        'vendidos': 0,
        'valorTotalDisponible': 0.0,
        'valorTotalVendido': 0.0,
      };
    }
  }

  // Método privado para verificar si un IMEI ya existe
  Future<bool> _verificarIMEIExiste(String imei, String? excludeId) async {
    if (imei.isEmpty) return false;

    try {
      final query = await _firestore
          .collection(_collectionName)
          .where('imei', isEqualTo: imei)
          .get();

      // Si excludeId se proporciona, excluir ese documento de la verificación
      if (excludeId != null) {
        return query.docs.any((doc) => doc.id != excludeId);
      }

      return query.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error al verificar IMEI: $e');
      return false;
    }
  }

  // Migrar datos antiguos (total -> precio) - función de utilidad
  Future<void> migrarDatosAntiguos() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      final batch = _firestore.batch();
      int contadorActualizaciones = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Si tiene 'total' pero no 'precio', migrar
        if (data.containsKey('total') && !data.containsKey('precio')) {
          batch.update(doc.reference, {
            'precio': data['total'],
            'stock': data['stock'] ?? 1,
            'disponible': data['disponible'] ?? true,
            'fechaActualizacion': FieldValue.serverTimestamp(),
          });
          contadorActualizaciones++;
        }
      }

      if (contadorActualizaciones > 0) {
        await batch.commit();
        print('✅ Migrados $contadorActualizaciones productos de total a precio');
      } else {
        print('ℹ️ No hay productos para migrar');
      }
    } catch (e) {
      print('❌ Error en migración: $e');
      throw Exception('Error en migración de datos: $e');
    }
  }
}