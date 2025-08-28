import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/venta.dart';
import '../../services/venta_service.dart';

class DetalleVentaScreen extends StatefulWidget {
  final Venta venta;

  const DetalleVentaScreen({
    super.key,
    required this.venta,
  });

  @override
  State<DetalleVentaScreen> createState() => _DetalleVentaScreenState();
}

class _DetalleVentaScreenState extends State<DetalleVentaScreen> {
  final VentasService _ventasService = VentasService();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "es_HN");
  List<DetalleVenta> _detalles = [];
  bool _cargandoDetalles = true;

  @override
  void initState() {
    super.initState();
    _cargarDetalles();
  }

  Future<void> _cargarDetalles() async {
    try {
      final detalles = await _ventasService.getDetallesVenta(widget.venta.id);
      setState(() {
        _detalles = detalles;
        _cargandoDetalles = false;
      });
    } catch (e) {
      setState(() {
        _cargandoDetalles = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar detalles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Venta ${widget.venta.numeroVenta}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (widget.venta.estado == 'completada')
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'cancelar':
                    _mostrarDialogoCancelar();
                    break;
                  case 'imprimir':
                    _imprimirFactura();
                    break;
                  case 'compartir':
                    _compartirFactura();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'imprimir',
                  child: Row(
                    children: [
                      Icon(Icons.print),
                      SizedBox(width: 8),
                      Text('Imprimir'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'compartir',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('Compartir'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'cancelar',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cancelar Venta', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderVenta(),
            _buildDetallesProductos(),
            _buildResumenVenta(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildHeaderVenta() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getEstadoColor(widget.venta.estado).withOpacity(0.1),
            _getEstadoColor(widget.venta.estado).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getEstadoColor(widget.venta.estado).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Número de Venta',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.venta.numeroVenta,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getEstadoColor(widget.venta.estado),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getEstadoTexto(widget.venta.estado),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Fecha', DateFormat('dd/MM/yyyy HH:mm').format(widget.venta.fechaVenta)),
          _buildInfoRow('Vendedor', widget.venta.vendedor.nombre),
          _buildInfoRow('Método de Pago', _formatearMetodoPago(widget.venta.metodoPago)),
          _buildInfoRow('Total', 'L. ${_currencyFormat.format(widget.venta.total)}', isTotal: true),
          if (widget.venta.observaciones != null && widget.venta.observaciones!.isNotEmpty)
            _buildInfoRow('Observaciones', widget.venta.observaciones!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String valor, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetallesProductos() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Productos Vendidos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_cargandoDetalles)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_detalles.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No se encontraron detalles',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _detalles.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final detalle = _detalles[index];
                return ListTile(
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
                    detalle.producto.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('IMEI: ${detalle.producto.imei}'),
                      Text('Cantidad: ${detalle.cantidad}'),
                      Text('Precio: L. ${_currencyFormat.format(detalle.precioUnitario)}'),
                    ],
                  ),
                  trailing: Text(
                    'L. ${_currencyFormat.format(detalle.subtotalProducto)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildResumenVenta() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de Pago',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildResumenRow('Subtotal', widget.venta.subtotal),
          _buildResumenRow('ISV (15%)', widget.venta.isv),
          const Divider(thickness: 1),
          _buildResumenRow('Total', widget.venta.total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildResumenRow(String label, double valor, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            'L. ${_currencyFormat.format(valor)}',
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    if (widget.venta.estado != 'completada') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _compartirFactura,
              icon: const Icon(Icons.share),
              label: const Text('Compartir'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _imprimirFactura,
              icon: const Icon(Icons.print),
              label: const Text('Imprimir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'completada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoTexto(String estado) {
    switch (estado.toLowerCase()) {
      case 'completada':
        return 'COMPLETADA';
      case 'cancelada':
        return 'CANCELADA';
      case 'pendiente':
        return 'PENDIENTE';
      default:
        return estado.toUpperCase();
    }
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

  void _mostrarDialogoCancelar() {
    final TextEditingController motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Venta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Está seguro que desea cancelar esta venta?'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo de cancelación',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (motivoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor ingrese un motivo'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                await _ventasService.cancelarVenta(
                  widget.venta.id,
                  motivoController.text.trim(),
                );

                if (mounted) {
                  Navigator.pop(context); // Cerrar dialog
                  Navigator.pop(context); // Volver a historial
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Venta cancelada exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al cancelar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancelar Venta'),
          ),
        ],
      ),
    );
  }

  void _imprimirFactura() {
    // TODO: Implementar impresión de factura
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de impresión próximamente'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _compartirFactura() {
    // TODO: Implementar compartir factura
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de compartir próximamente'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}