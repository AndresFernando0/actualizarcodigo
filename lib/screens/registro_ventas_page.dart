import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/venta.dart';
import '../services/venta_service.dart';
import 'detalle_venta.dart';

class RegistroVentasScreen extends StatefulWidget {
  const RegistroVentasScreen({super.key});

  @override
  State<RegistroVentasScreen> createState() => _RegistroVentasScreenState();
}

class _RegistroVentasScreenState extends State<RegistroVentasScreen> {
  final VentasService _ventasService = VentasService();
  final TextEditingController _observacionesController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "es_HN");
  
  List<ProductoInventario> _productosDisponibles = [];
  List<Map<String, dynamic>> _carritoVenta = [];
  String _metodoPago = 'efectivo';
  bool _procesandoVenta = false;

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return _carritoVenta.fold(0, (sum, item) {
      final producto = item['producto'] as ProductoInventario;
      final cantidad = item['cantidad'] as int;
      return sum + (producto.precio * cantidad);
    });
  }

  double get _isv => _subtotal * 0.15;
  double get _total => _subtotal + _isv;

  void _agregarProductoAlCarrito(ProductoInventario producto) {
    showDialog(
      context: context,
      builder: (context) => _CantidadDialog(
        producto: producto,
        onConfirmar: (cantidad) {
          setState(() {
            // VERIFICAR SI EL PRODUCTO ESTA EN EL CARRITO
            final index = _carritoVenta.indexWhere((item) => 
                (item['producto'] as ProductoInventario).id == producto.id);
            
            if (index >= 0) {
              // ACTUALIZAR CANTIDAD
              _carritoVenta[index]['cantidad'] = cantidad;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cantidad actualizada para ${producto.nombre}'),
                  backgroundColor: Colors.blue,
                ),
              );
            } else {
              // Agregar nuevo producto
              _carritoVenta.add({
                'producto': producto,
                'cantidad': cantidad,
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${producto.nombre} agregado al carrito'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          });
        },
      ),
    );
  }

  void _editarCantidadProducto(int index) {
    final item = _carritoVenta[index];
    final producto = item['producto'] as ProductoInventario;
    final cantidadActual = item['cantidad'] as int;

    showDialog(
      context: context,
      builder: (context) => _CantidadDialog(
        producto: producto,
        cantidadInicial: cantidadActual,
        onConfirmar: (cantidad) {
          setState(() {
            _carritoVenta[index]['cantidad'] = cantidad;
          });
        },
      ),
    );
  }

  void _eliminarProductoDelCarrito(int index) {
    final producto = (_carritoVenta[index]['producto'] as ProductoInventario).nombre;
    setState(() {
      _carritoVenta.removeAt(index);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$producto eliminado del carrito'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () {
            // DESHACER
          },
        ),
      ),
    );
  }

Future<void> _procesarVenta() async {
  if (_carritoVenta.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 10),
            Text('Agregue productos al carrito para hacer la venta'),
          ],
        ),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  setState(() {
    _procesandoVenta = true;
  });

  try {
    // CAPTURAR LOS VALORES ANTES DE LIMPIAR EL CARRITO
    final totalVenta = _total;
    final metodoPagoVenta = _metodoPago;
    
    final ventaId = await _ventasService.procesarVenta(
      productosSeleccionados: _carritoVenta,
      metodoPago: _metodoPago,
      observaciones: _observacionesController.text.trim().isEmpty 
          ? null 
          : _observacionesController.text.trim(),
    );

    if (mounted) {
      // LIMPIAR CARRITO
      setState(() {
        _carritoVenta.clear();
        _observacionesController.clear();
        _metodoPago = 'efectivo';
      });

      // MOSTRAR CONFIRMACION CON LOS VALORES CAPTURADOS
      await _mostrarConfirmacionVenta(ventaId, totalVenta, metodoPagoVenta);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Error al procesar la venta: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _procesandoVenta = false;
      });
    }
  }
}

// METODO PARA MOSTRAR LA CONFIRMACION
Future<void> _mostrarConfirmacionVenta(String ventaId, double totalVenta, String metodoPagoVenta) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ICONO EXITO
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          
          // TITULO
          const Text(
            '¡Venta Procesada!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          
          // MENSAJE
          const Text(
            'La venta se ha procesado exitosamente.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          // DETALLES DE LA VENTA
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:'),
                    Text(
                      'L. ${_currencyFormat.format(totalVenta)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Metodo:'),
                    Text(_formatearMetodoPago(metodoPagoVenta)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '¿Que desea hacer ahora?', 
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Continuar Vendiendo'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (context) => FacturaScreen(ventaId: ventaId),
              ),
            );
          },
          icon: const Icon(Icons.receipt),
          label: const Text('Ver Factura'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
}
  String _formatearMetodoPago(String metodoPago) {
    switch (metodoPago.toLowerCase()) {
      case 'efectivo':
        return 'Efectivo';
      case 'tarjeta':
        return 'Tarjeta';
      case 'transferencia':
        return 'Transferencia';
      default:
        return metodoPago;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Ventas'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_carritoVenta.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Limpiar Carrito'),
                    content: const Text('¿Esta seguro de que desea limpiar todo el carrito?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _carritoVenta.clear());
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Limpiar'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Limpiar carrito',
            ),
        ],
      ),
      body: Column(
        children: [
          // HEADER INFORMACION DE VENTA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Nueva Venta - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Productos en carrito: ${_carritoVenta.length}'),
                    Text(
                      'Total: L. ${_currencyFormat.format(_total)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // PRODUCTOS QUE ESTAN DISPONIBLES
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Productos Disponibles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<ProductoInventario>>(
                    stream: _ventasService.getProductosDisponibles(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text('Error: ${snapshot.error}'),
                              ElevatedButton(
                                onPressed: () => setState(() {}),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      _productosDisponibles = snapshot.data ?? [];
                      
                      if (_productosDisponibles.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No hay productos disponibles para la venta'),
                              SizedBox(height: 8),
                              Text(
                                'Agregue productos al inventario primero',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async => setState(() {}),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _productosDisponibles.length,
                          itemBuilder: (context, index) {
                            final producto = _productosDisponibles[index];
                            final yaEnCarrito = _carritoVenta.any((item) => 
                                (item['producto'] as ProductoInventario).id == producto.id);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: yaEnCarrito ? 3 : 1,
                              color: yaEnCarrito ? Colors.green.withOpacity(0.05) : null,
                              child: ListTile(
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: yaEnCarrito 
                                        ? Colors.green.withOpacity(0.2) 
                                        : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: yaEnCarrito 
                                        ? Border.all(color: Colors.green, width: 2)
                                        : null,
                                  ),
                                  child: Icon(
                                    Icons.phone_android, 
                                    color: yaEnCarrito ? Colors.green[700] : Colors.green,
                                  ),
                                ),
                                title: Text(
                                  producto.nombre,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: yaEnCarrito ? Colors.green[700] : null,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (producto.imei.isNotEmpty) 
                                      Text('IMEI: ${producto.imei}'),
                                    Text('Stock: ${producto.stock}'),
                                    Text(
                                      'Precio: L. ${_currencyFormat.format(producto.precio)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        color: Colors.green,
                                      ),
                                    ),
                                    if (yaEnCarrito)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'EN CARRITO',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: ElevatedButton.icon(
                                  onPressed: () => _agregarProductoAlCarrito(producto),
                                  icon: Icon(
                                    yaEnCarrito ? Icons.edit : Icons.add_shopping_cart, 
                                    size: 16,
                                  ),
                                  label: Text(yaEnCarrito ? 'Editar' : 'Agregar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: yaEnCarrito ? Colors.blue : Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // CARRITO
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shopping_cart, color: Colors.green),
                            const SizedBox(width: 8),
                            const Text(
                              'Carrito de Venta',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (_carritoVenta.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _carritoVenta.clear();
                              });
                            },
                            icon: const Icon(Icons.clear, size: 16),
                            label: const Text('Limpiar'),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _carritoVenta.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('El carrito está vacio'),
                                Text('Agregue productos para continuar'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _carritoVenta.length,
                            itemBuilder: (context, index) {
                              final item = _carritoVenta[index];
                              final producto = item['producto'] as ProductoInventario;
                              final cantidad = item['cantidad'] as int;
                              final subtotal = producto.precio * cantidad;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 2,
                                child: ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.phone_android, color: Colors.blue),
                                  ),
                                  title: Text(
                                    producto.nombre,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (producto.imei.isNotEmpty) 
                                        Text('IMEI: ${producto.imei}'),
                                      Text('Cantidad: $cantidad x L. ${_currencyFormat.format(producto.precio)}'),
                                    ],
                                  ),
                                  trailing: SizedBox(
                                    width: 140,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'L. ${_currencyFormat.format(subtotal)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold, 
                                            color: Colors.green,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              onPressed: () => _editarCantidadProducto(index),
                                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                              padding: EdgeInsets.zero,
                                              tooltip: 'Editar cantidad',
                                            ),
                                            IconButton(
                                              onPressed: () => _eliminarProductoDelCarrito(index),
                                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                              padding: EdgeInsets.zero,
                                              tooltip: 'Eliminar del carrito',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // RESUMEN Y BOTON PROCESAR
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('L. ${_currencyFormat.format(_subtotal)}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ISV (15%):', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('L. ${_currencyFormat.format(_isv)}'),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      'L. ${_currencyFormat.format(_total)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // METODO DE PAGO
                DropdownButtonFormField<String>(
                  value: _metodoPago,
                  decoration: const InputDecoration(
                    labelText: 'Metodo de pago',
                    prefixIcon: Icon(Icons.payment),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'efectivo', 
                      child: Row(
                        children: [
                          Icon(Icons.money, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('Efectivo'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'tarjeta', 
                      child: Row(
                        children: [
                          Icon(Icons.credit_card, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text('Tarjeta'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'transferencia', 
                      child: Row(
                        children: [
                          Icon(Icons.account_balance, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text('Transferencia'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _metodoPago = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                // OBSERVACIONES
                TextField(
                  controller: _observacionesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones (opcional)',
                    hintText: 'Notas adicionales sobre la venta...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
                const SizedBox(height: 16),
                // BOTON PROCESAR VENTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _procesandoVenta || _carritoVenta.isEmpty ? null : _procesarVenta,
                    icon: _procesandoVenta
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(
                      _procesandoVenta 
                          ? 'Procesando Venta...' 
                          : _carritoVenta.isEmpty 
                              ? 'Agregue productos al carrito' 
                              : 'Procesar Venta',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _carritoVenta.isEmpty ? Colors.grey : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// SELECCIONAR CANTIDAD DIALOG
class _CantidadDialog extends StatefulWidget {
  final ProductoInventario producto;
  final int? cantidadInicial;
  final void Function(int cantidad) onConfirmar;

  const _CantidadDialog({
    required this.producto,
    required this.onConfirmar,
    this.cantidadInicial,
  });

  @override
  State<_CantidadDialog> createState() => _CantidadDialogState();
}

class _CantidadDialogState extends State<_CantidadDialog> {
  final TextEditingController _cantidadController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "es_HN");
  int _cantidad = 1;

  @override
  void initState() {
    super.initState();
    _cantidad = widget.cantidadInicial ?? 1;
    _cantidadController.text = _cantidad.toString();
  }

  void _actualizarCantidad(int nuevaCantidad) {
    if (nuevaCantidad >= 1 && nuevaCantidad <= widget.producto.stock) {
      setState(() {
        _cantidad = nuevaCantidad;
        _cantidadController.text = _cantidad.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.producto.precio * _cantidad;

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cantidad - ${widget.producto.nombre}'),
          Text(
            'Precio: L. ${_currencyFormat.format(widget.producto.precio)}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _cantidad > 1 ? () => _actualizarCantidad(_cantidad - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 32,
              ),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _cantidadController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Cantidad',
                  ),
                  onChanged: (value) {
                    final nuevaCantidad = int.tryParse(value) ?? 1;
                    _actualizarCantidad(nuevaCantidad);
                  },
                ),
              ),
              IconButton(
                onPressed: _cantidad < widget.producto.stock 
                    ? () => _actualizarCantidad(_cantidad + 1) 
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 32,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Stock disponible: ${widget.producto.stock}'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text('Subtotal:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'L. ${_currencyFormat.format(subtotal)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_cantidad > 0 && _cantidad <= widget.producto.stock) {
              widget.onConfirmar(_cantidad);
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cantidad invalida. Stock disponible: ${widget.producto.stock}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}