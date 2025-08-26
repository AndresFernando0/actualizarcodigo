import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/venta.dart';

class VentasService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _ventasRef = FirebaseFirestore.instance.collection('ventas');
  final CollectionReference _detalleVentasRef = FirebaseFirestore.instance.collection('detalleVentas');
  final CollectionReference _inventarioRef = FirebaseFirestore.instance.collection('inventario');

  // Obtener productos disponibles para venta
  Stream<List<ProductoInventario>> getProductosDisponibles() {
    return _inventarioRef
        .where('stock', isGreaterThan: 0)
        .where('disponible', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductoInventario.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Generar número de venta único
  Future<String> _generarNumeroVenta() async {
    final now = DateTime.now();
    final fecha = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    
    final query = await _ventasRef
        .where('numeroVenta', isGreaterThanOrEqualTo: 'VTA-$fecha-')
        .where('numeroVenta', isLessThan: 'VTA-$fecha-999')
        .orderBy('numeroVenta', descending: true)
        .limit(1)
        .get();

    int siguiente = 1;
    if (query.docs.isNotEmpty) {
      final ultimoNumero = query.docs.first.data() as Map<String, dynamic>;
      final numeroStr = ultimoNumero['numeroVenta'] as String;
      final partes = numeroStr.split('-');
      if (partes.length == 3) {
        siguiente = int.parse(partes[2]) + 1;
      }
    }

    return 'VTA-$fecha-${siguiente.toString().padLeft(3, '0')}';
  }

  // Obtener datos del vendedor logueado
  Future<Vendedor> _getVendedorActual() async {
    final prefs = await SharedPreferences.getInstance();
    return Vendedor(
      id: prefs.getString('userId') ?? '',
      nombre: prefs.getString('nombre') ?? '',
      usuario: prefs.getString('usuario') ?? '',
    );
  }

  // Procesar venta completa
  Future<String> procesarVenta({
    required List<Map<String, dynamic>> productosSeleccionados, // {producto: ProductoInventario, cantidad: int}
    required String metodoPago,
    String? observaciones,
  }) async {
    try {
      // Validaciones previas
      if (productosSeleccionados.isEmpty) {
        throw Exception('No hay productos seleccionados');
      }

      // Verificar stock disponible
      for (var item in productosSeleccionados) {
        final producto = item['producto'] as ProductoInventario;
        final cantidad = item['cantidad'] as int;
        
        final docSnapshot = await _inventarioRef.doc(producto.id).get();
        if (!docSnapshot.exists) {
          throw Exception('El producto ${producto.nombre} ya no existe');
        }
        
        final stockActual = docSnapshot.data() as Map<String, dynamic>;
        final stockDisponible = stockActual['stock'] ?? 0;
        
        if (stockDisponible < cantidad) {
          throw Exception('Stock insuficiente para ${producto.nombre}. Disponible: $stockDisponible');
        }
      }

      // Generar datos de la venta
      final numeroVenta = await _generarNumeroVenta();
      final vendedor = await _getVendedorActual();
      final fechaVenta = DateTime.now();

      // Calcular totales
      double subtotal = 0;
      for (var item in productosSeleccionados) {
        final producto = item['producto'] as ProductoInventario;
        final cantidad = item['cantidad'] as int;
        subtotal += producto.precio * cantidad;
      }

      final isv = subtotal * 0.15; // 15% ISV
      final total = subtotal + isv;

      // Crear la venta
      final venta = Venta(
        id: '',
        numeroVenta: numeroVenta,
        fechaVenta: fechaVenta,
        vendedor: vendedor,
        metodoPago: metodoPago,
        subtotal: subtotal,
        isv: isv,
        total: total,
        cantidadProductos: productosSeleccionados.length,
        fechaCreacion: fechaVenta,
        observaciones: observaciones,
      );

      // Transacción atómica
      return await _firestore.runTransaction<String>((transaction) async {
        // 1. Crear documento de venta
        final ventaRef = _ventasRef.doc();
        transaction.set(ventaRef, venta.toMap());

        // 2. Crear detalles de venta y actualizar inventario
        for (var item in productosSeleccionados) {
          final producto = item['producto'] as ProductoInventario;
          final cantidad = item['cantidad'] as int;
          final subtotalProducto = producto.precio * cantidad;

          // Crear detalle de venta
          final detalleVenta = DetalleVenta(
            id: '',
            ventaId: ventaRef.id,
            numeroVenta: numeroVenta,
            producto: ProductoVendido(
              inventarioId: producto.id,
              nombre: producto.nombre,
              imei: producto.imei,
            ),
            cantidad: cantidad,
            precioUnitario: producto.precio,
            subtotalProducto: subtotalProducto,
            fechaVenta: fechaVenta,
            vendedor: vendedor.nombre,
          );

          final detalleRef = _detalleVentasRef.doc();
          transaction.set(detalleRef, detalleVenta.toMap());

          // Actualizar stock en inventario
          final inventarioRef = _inventarioRef.doc(producto.id);
          final nuevoStock = producto.stock - cantidad;
          
          transaction.update(inventarioRef, {
            'stock': nuevoStock,
            'disponible': nuevoStock > 0,
            'fechaActualizacion': FieldValue.serverTimestamp(),
          });
        }

        return ventaRef.id;
      });

    } catch (e) {
      print('Error al procesar venta: $e');
      rethrow;
    }
  }

  // Obtener todas las ventas
  Stream<List<Venta>> getVentas() {
    return _ventasRef
        .orderBy('fechaVenta', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Venta.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Obtener detalle de una venta específica
  Future<List<DetalleVenta>> getDetalleVenta(String ventaId) async {
    final snapshot = await _detalleVentasRef
        .where('ventaId', isEqualTo: ventaId)
        .get();

    return snapshot.docs.map((doc) {
      return DetalleVenta.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  // Obtener venta por ID
  Future<Venta?> getVentaById(String ventaId) async {
    final doc = await _ventasRef.doc(ventaId).get();
    if (doc.exists) {
      return Venta.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Buscar ventas con filtros
  Future<List<Venta>> buscarVentas({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? vendedor,
    String? metodoPago,
  }) async {
    Query query = _ventasRef;

    if (fechaInicio != null) {
      query = query.where('fechaVenta',
          isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio));
    }

    if (fechaFin != null) {
      query = query.where('fechaVenta',
          isLessThanOrEqualTo: Timestamp.fromDate(fechaFin));
    }

    if (vendedor != null && vendedor.isNotEmpty) {
      query = query.where('vendedor.nombre', isEqualTo: vendedor);
    }

    if (metodoPago != null && metodoPago.isNotEmpty) {
      query = query.where('metodoPago', isEqualTo: metodoPago);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      return Venta.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }
}