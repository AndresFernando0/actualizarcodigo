import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/venta.dart';
import '../services/venta_service.dart';
import 'detalle_venta.dart';

class HistorialVentasScreen extends StatefulWidget {
  const HistorialVentasScreen({super.key});

  @override
  State<HistorialVentasScreen> createState() => _HistorialVentasScreenState();
}

class _HistorialVentasScreenState extends State<HistorialVentasScreen>
    with SingleTickerProviderStateMixin {
  final VentasService _ventasService = VentasService();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "es_HN");
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Ventas'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Hoy', icon: Icon(Icons.today)),
            Tab(text: 'Todas', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVentasHoy(),
          _buildTodasLasVentas(),
        ],
      ),
    );
  }

  Widget _buildVentasHoy() {
    return Column(
      children: [
        _buildEstadisticasHoy(),
        Expanded(
          child: StreamBuilder<List<Venta>>(
            stream: _ventasService.getVentasHoy(),
            builder: (context, snapshot) {
              return _buildListaVentas(snapshot, 'No hay ventas registradas hoy');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTodasLasVentas() {
    return StreamBuilder<List<Venta>>(
      stream: _ventasService.getVentas(limit: 50), // Limitar a 50 para rendimiento
      builder: (context, snapshot) {
        return _buildListaVentas(snapshot, 'No hay ventas registradas');
      },
    );
  }

  Widget _buildEstadisticasHoy() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _ventasService.getEstadisticasVentas(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Resumen de Hoy',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Ventas',
                      '${stats['ventasHoy']}',
                      Icons.shopping_cart,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Total',
                      'L. ${_currencyFormat.format(stats['totalHoy'])}',
                      Icons.attach_money,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildListaVentas(AsyncSnapshot<List<Venta>> snapshot, String emptyMessage) {
    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${snapshot.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando ventas...'),
          ],
        ),
      );
    }

    final ventas = snapshot.data ?? [];
    
    if (ventas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ventas.length,
      itemBuilder: (context, index) {
        final venta = ventas[index];
        return _buildVentaCard(venta);
      },
    );
  }

  Widget _buildVentaCard(Venta venta) {
    final isToday = _isToday(venta.fechaVenta);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _verDetalleVenta(venta),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venta.numeroVenta,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(venta.fechaVenta),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'L. ${_currencyFormat.format(venta.total)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getEstadoColor(venta.estado),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getEstadoTexto(venta.estado),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    venta.vendedor.nombre,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatearMetodoPago(venta.metodoPago),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.shopping_cart, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${venta.cantidadProductos} ${venta.cantidadProductos == 1 ? 'artículo' : 'artículos'}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              if (venta.observaciones != null && venta.observaciones!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Obs: ${venta.observaciones!}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime fecha) {
    final now = DateTime.now();
    return fecha.year == now.year && 
           fecha.month == now.month && 
           fecha.day == now.day;
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

  void _verDetalleVenta(Venta venta) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleVentaScreen(venta: venta),
      ),
    );
  }
}