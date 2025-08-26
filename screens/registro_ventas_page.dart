import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/venta.dart';
import '../services/venta_service.dart';

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
  List<Map<String, dynamic>> _carritoVenta = []; // {producto: ProductoInventario, cantidad: int}
  String _metodoPago = 'efectivo';
  bool _cargando = false;
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
            // Verificar si el producto ya está en el carrito
            final index = _carritoVenta.indexWhere((item) => 
                (item['producto'] as ProductoInventario).id == producto.id);
            
            if (index >= 0) {
              // Actualizar cantidad
              _carritoVenta[index]['cantidad'] = cantidad;
            } else {
              // Agregar nuevo producto
              _carritoVenta.add({
                'producto': producto,
                'cantidad': cantidad,
              });
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
    setState(() {
      _carritoVenta.removeAt(index);
    });
  }

  Future<void> _procesarVenta() async {
    if (_carritoVenta.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agregue productos al carrito para procesar la venta'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _procesandoVenta = true;
    });

    try {
      final ventaId = await _ventasService.procesarVenta(
        productosSeleccionados: _carritoVenta,
        metodoPago: _metodoPago,
        observaciones: _observacionesController.text.trim().isEmpty 
            ? null 
            : _observacionesController.text.trim(),
      );

      if (mounted) {
        // Limpiar carrito
        setState(() {
          _carritoVenta.clear();
          _observacionesController.clear();
          _metodoPago = 'efectivo';
        });

        // Mostrar confirmación
        await _mostrarConfirmacionVenta(ventaId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la venta: ${e.toString()}'),
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

  Future<void> _mostrarConfirmacionVenta(String ventaId) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 10),
            Text('¡Venta Procesada!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('La venta se ha procesado exitosamente.'),
            const SizedBox(height: 10),
            Text('Total: L. ${_currencyFormat.format(_total)}'),
            Text('Método: $_metodoPago'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Aquí podrías navegar a la pantalla de factura
              // Navigator.push(context, MaterialPageRoute(builder: (context) => FacturaScreen(ventaId: ventaId)));
            },
            child: const Text('Ver Factura'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Ventas'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header con información de la venta
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Productos en carrito: ${_carritoVenta.length}'),
                    Text(
                      'Total: L. ${_currencyFormat.format(_total)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Productos disponibles
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
                        return Center(child: Text('Error: ${snapshot.error}'));
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
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _productosDisponibles.length,
                        itemBuilder: (context, index) {
                          final producto = _productosDisponibles[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.phone_android, color: Colors.green),
                              ),
                              title: Text(
                                producto.nombre,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('IMEI: ${producto.imei}'),
                                  Text('Stock: ${producto.stock}'),
                                  Text(
                                    'Precio: L. ${_currencyFormat.format(producto.precio)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ],
                              ),
                              trailing: ElevatedButton.icon(
                                onPressed: () => _agregarProductoAlCarrito(producto),
                                icon: const Icon(Icons.add_shopping_cart, size: 16),
                                label: const Text('Agregar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Carrito de venta
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
                        const Text(
                          'Carrito de Venta',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (_carritoVenta.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _carritoVenta.clear();
                              });
                            },
                            child: const Text('Limpiar', style: TextStyle(color: Colors.red)),
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
                                Text('El carrito está vacío'),
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
                                child: ListTile(
                                  title: Text(producto.nombre),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('IMEI: ${producto.imei}'),
                                      Text('Cantidad: $cantidad x L. ${_currencyFormat.format(producto.
Text('Cantidad: $cantidad x L. ${_currencyFormat.format(producto.precio)}'),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'L. ${_currencyFormat.format(subtotal)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: () => _editarCantidadProducto(index),
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                          ),
                                          IconButton(
                                            onPressed: () => _eliminarProductoDelCarrito(index),
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ],
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

          // Resumen y botón procesar
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
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      'L. ${_currencyFormat.format(_total)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Método de pago
                DropdownButtonFormField<String>(
                  value: _metodoPago,
                  decoration: const InputDecoration(labelText: 'Método de pago'),
                  items: const [
                    DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                    DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                    DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
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
                // Observaciones
                TextField(
                  controller: _observacionesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // Botón Procesar Venta
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _procesandoVenta ? null : _procesarVenta,
                    icon: _procesandoVenta
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(_procesandoVenta ? 'Procesando...' : 'Procesar Venta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

// Dialog para seleccionar cantidad
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

  @override
  void initState() {
    super.initState();
    _cantidadController.text = (widget.cantidadInicial ?? 1).toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Cantidad - ${widget.producto.nombre}'),
      content: TextField(
        controller: _cantidadController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(labelText: 'Cantidad'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final cantidad = int.tryParse(_cantidadController.text) ?? 1;
            if (cantidad > 0 && cantidad <= widget.producto.stock) {
              widget.onConfirmar(cantidad);
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cantidad inválida. Stock disponible: ${widget.producto.stock}'),
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
