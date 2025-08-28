import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventario.dart';

class InventarioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'inventario';

  // OBTENER INVENTARIO COMPLETO EN TIEMPO REAL
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

  // OBTENER SOLO LOS PRODUCTOS QUE ESTAN DISPONIBLES PARA LA VENTA
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

  // GUARDAR MULTIPLES PRODUCTOS EN INVENTARIO
  Future<void> guardarInventario(List<Inventario> productos) async {
    final batch = _firestore.batch();
    
    try {
      print('🔄 Guardando ${productos.length} productos en inventario...');
      
      for (final producto in productos) {
        // VALIDACIONES
        if (producto.nombre.isEmpty) {
          throw Exception('El nombre del producto no puede estar vacio');
        }
        
        if (producto.precio <= 0) {
          throw Exception('El precio debe ser mayor a 0');
        }

        // VERIFICAR SI EL IMEI YA EXISTE (solo si no está vacio)
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

  // GUARDAR UN SOLO PRODUCTO
  Future<String> guardarProductoIndividual(Inventario producto) async {
    try {
      // VALIDACIONES
      if (producto.nombre.isEmpty) {
        throw Exception('El nombre del producto no puede estar vacio');
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

  // ACTUALIZAR UN PRODUCTO QUE YA EXISTE
  Future<void> actualizarProducto(String id, Inventario producto) async {
    try {
      // VALIDACIONES
      if (producto.nombre.isEmpty) {
        throw Exception('El nombre del producto no puede estar vacio');
      }
      
      if (producto.precio <= 0) {
        throw Exception('El precio debe ser mayor a 0');
      }

      // VERIFICAR SI EL IMEI EXISTE EN OTRO TELEFONO (solo si no está vacio)
      if (producto.imei.isNotEmpty) {
        final existeIMEI = await _verificarIMEIExiste(producto.imei, id);
        if (existeIMEI) {
          throw Exception('Ya existe otro telefono con el IMEI: ${producto.imei}');
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

  // MARCAR PRODUCTO COMO VENDIDO
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

  // RESTAURAR DISPONIBILIDAD DE PRODUCTO (para cancelacion de venta)
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

  // ELIMINAR PRODUCTO DE INVENTARIO
  Future<void> eliminarItemInventario(String id) async {
    try {
      // VERIFICAR SI EL PRODUCTO EXISTE
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      if (!doc.exists) {
        throw Exception('El producto no existe');
      }

      // OBTENER DATOS DEL LOGIN
      final producto = Inventario.fromMap(doc.id, doc.data()!);
      
      // ELIMINAR EL DOCUMENTO
      await _firestore.collection(_collectionName).doc(id).delete();
      
      print('🗑️ Producto eliminado del inventario: ${producto.nombre}');
    } catch (e) {
      print('❌ Error al eliminar producto: $e');
      throw Exception('Error al eliminar producto: $e');
    }
  }

  // OBTENER PRODUCTO POR ID
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

  // BUSCAR PRODUCTO POR NOMBRE O IMEI
  Future<List<Inventario>> buscarProductos(String termino) async {
    try {
      if (termino.isEmpty) return [];

      final terminoLower = termino.toLowerCase();
      
      // OBTENER TODOS LOS PRODUCTOS Y FILTRAR LOCALMENTE
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

  // OBTENER ESTADISTICAS DE INVENTARIO
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

  // METODO PRIVADO PARA VERIFICAR SI UN IMEI YA EXISTE
  Future<bool> _verificarIMEIExiste(String imei, String? excludeId) async {
    if (imei.isEmpty) return false;

    try {
      final query = await _firestore
          .collection(_collectionName)
          .where('imei', isEqualTo: imei)
          .get();

      // SI EXCLUDEID SE PROPORCIONA, EXCLUIR ESE DOCUMENTO DE LA VERIFICACION
      if (excludeId != null) {
        return query.docs.any((doc) => doc.id != excludeId);
      }

      return query.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error al verificar IMEI: $e');
      return false;
    }
  }

  // MIGRAR DATOS ANTIGUOS (total -> precio) FUNCION DE UTILIDAD
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