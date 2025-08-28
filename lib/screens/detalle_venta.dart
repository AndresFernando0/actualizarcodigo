import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/venta.dart';
import '../services/venta_service.dart';

class FacturaScreen extends StatefulWidget {
  final String ventaId;

  const FacturaScreen({
    super.key,
    required this.ventaId,
  });

  @override
  State<FacturaScreen> createState() => _FacturaScreenState();
}

class _FacturaScreenState extends State<FacturaScreen> {
  final VentasService _ventasService = VentasService();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "es_HN");
  
  Venta? _venta;
  List<DetalleVenta> _detalles = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      setState(() {
        _cargando = true;
        _error = null;
      });

      // Buscar la venta por ID
      final ventasStream = _ventasService.getVentas();
      await for (final ventas in ventasStream) {
        final venta = ventas.firstWhere(
          (v) => v.id == widget.ventaId,
          orElse: () => throw Exception('Venta no encontrada'),
        );
        
        final detalles = await _ventasService.getDetallesVenta(widget.ventaId);
        
        setState(() {
          _venta = venta;
          _detalles = detalles;
          _cargando = false;
        });
        break;
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Factura de Venta'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_venta != null) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _compartirFactura,
              tooltip: 'Compartir',
            ),
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _imprimirFactura,
              tooltip: 'Imprimir',
            ),
          ],
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _venta == null
                  ? const Center(child: Text('Venta no encontrada'))
                  : _buildFacturaContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Error al cargar la factura'),
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargarDatos,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildFacturaContent() {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEncabezadoFactura(),
            const Divider(height: 30, thickness: 1),
            _buildInformacionVenta(),
            const SizedBox(height: 20),
            _buildDetallesProductos(),
            const Divider(height: 30, thickness: 1),
            _buildResumenPago(),
            const SizedBox(height: 30),
            _buildPieFactura(),
          ],
        ),
      ),
    );
  }

  Widget _buildEncabezadoFactura() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FACTURA DE VENTA',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu Empresa S.A. de C.V.',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('San Pedro Sula, Cortés'),
                const Text('Teléfono: +504 0000-0000'),
                const Text('Email: ventas@empresa.com'),
                const Text('RTN: 00000000000000'),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'No. ${_venta!.numeroVenta}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd/MM/yyyy').format(_venta!.fechaVenta),
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    DateFormat('HH:mm').format(_venta!.fechaVenta),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInformacionVenta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'INFORMACIÓN DE LA VENTA',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Vendedor:', _venta!.vendedor.nombre),
                  _buildInfoRow('Usuario:', _venta!.vendedor.usuario),
                  _buildInfoRow('Método de Pago:', _formatearMetodoPago(_venta!.metodoPago)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Estado:', _venta!.estado.toUpperCase()),
                  _buildInfoRow('Productos:', '${_venta!.cantidadProductos}'),
                  if (_venta!.observaciones != null && _venta!.observaciones!.isNotEmpty)
                    _buildInfoRow('Observaciones:', _venta!.observaciones!),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildDetallesProductos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DETALLE DE PRODUCTOS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Encabezado de tabla
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 3, child: Text('PRODUCTO', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('IMEI', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('CANT.', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text('PRECIO', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                    Expanded(flex: 2, child: Text('SUBTOTAL', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                  ],
                ),
              ),
              // Filas de productos
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _detalles.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final detalle = _detalles[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            detalle.producto.nombre,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            detalle.producto.imei,
                            style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${detalle.cantidad}',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'L. ${_currencyFormat.format(detalle.precioUnitario)}',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'L. ${_currencyFormat.format(detalle.subtotalProducto)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResumenPago() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              _buildResumenRow('Subtotal:', _venta!.subtotal),
              const SizedBox(height: 8),
              _buildResumenRow('ISV (15%):', _venta!.isv),
              const Divider(thickness: 1),
              _buildResumenRow('TOTAL:', _venta!.total, isTotal: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResumenRow(String label, double valor, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          'L. ${_currencyFormat.format(valor)}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.green[700] : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPieFactura() {
    return Column(
      children: [
        const Text(
          '¡Gracias por su compra!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'TÉRMINOS Y CONDICIONES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '• Esta factura es válida por 30 días\n'
          '• Los productos vendidos tienen garantía según términos del fabricante\n'
          '• No se aceptan cambios ni devoluciones sin esta factura\n'
          '• Para soporte técnico contactar al 504-0000-0000',
          style: TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Factura generada el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  String _formatearMetodoPago(String metodoPago) {
    switch (metodoPago.toLowerCase()) {
      case 'efectivo':
        return 'Efectivo';
      case 'tarjeta':
        return 'Tarjeta de Crédito/Débito';
      case 'transferencia':
        return 'Transferencia Bancaria';
      default:
        return metodoPago;
    }
  }

  void _compartirFactura() {
    // TODO: Implementar compartir factura
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 10),
            Text('Función de compartir próximamente'),
          ],
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _imprimirFactura() {
    // TODO: Implementar impresión de factura
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 10),
            Text('Función de impresión próximamente'),
          ],
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }
}