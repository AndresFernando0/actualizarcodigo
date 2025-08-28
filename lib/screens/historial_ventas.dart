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

class _HistorialVentasScreenState extends State<HistorialVentasScreen> {
  final VentasService _ventasService = VentasService();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "es_HN");
  final TextEditingController _searchController = TextEditingController();
  String _filtroEstado = 'todos';
  String _filtroFecha = 'todos';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Ventas'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildEstadisticas(),
          Expanded(child: _buildListaVentas()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          labelText: 'Buscar por numero de venta',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          setState(() {}); 
        },
      ),
    );
  }

  Widget _buildEstadisticas() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _ventasService.getEstadisticasVentas(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
        }

        final stats = snapshot.data!;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Hoy',
                  '${stats['ventasHoy']} ventas',
                  'L. ${_currencyFormat.format(stats['totalHoy'])}',
                  Icons.today,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Este Mes',
                  '${stats['ventasMes']} ventas',
                  'L. ${_currencyFormat.format(stats['totalMes'])}',
                  Icons.calendar_month,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String titulo, String cantidad, String total, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(height: 8),
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(cantidad, style: const TextStyle(fontSize: 12)),
        Text(total, style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildListaVentas() {
    return StreamBuilder<List<Venta>>(
      stream: _ventasService.getVentas(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var ventas = snapshot.data ?? [];

        // APLICAR FILTROS 
        ventas = _aplicarFiltros(ventas);

        if (ventas.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No se encontraron ventas'),
                Text('Las ventas aparecerán aquí una vez realizadas'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ventas.length,
          itemBuilder: (context, index) {
            final venta = ventas[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getColorEstado(venta.estado).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt,
                    color: _getColorEstado(venta.estado),
                  ),
                ),
                title: Text(
                  'Venta ${venta.numeroVenta}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vendedor: ${venta.vendedor.nombre}'),
                    Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(venta.fechaVenta)}'),
                    Text('Productos: ${venta.cantidadProductos}'),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'L. ${_currencyFormat.format(venta.total)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getColorEstado(venta.estado),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getTextoEstado(venta.estado),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FacturaScreen(ventaId: venta.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  List<Venta> _aplicarFiltros(List<Venta> ventas) {
    List<Venta> ventasFiltradas = List.from(ventas);

    // FILTRO POR BUSQUEDA
    if (_searchController.text.isNotEmpty) {
      ventasFiltradas = ventasFiltradas.where((venta) =>
          venta.numeroVenta.toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }

    // FILTRO POR ESTADO
    if (_filtroEstado != 'todos') {
      ventasFiltradas = ventasFiltradas.where((venta) =>
          venta.estado == _filtroEstado
      ).toList();
    }

    // FILTRO POR FECHA
    if (_filtroFecha != 'todos') {
      final now = DateTime.now();
      switch (_filtroFecha) {
        case 'hoy':
          final hoy = DateTime(now.year, now.month, now.day);
          ventasFiltradas = ventasFiltradas.where((venta) =>
              venta.fechaVenta.isAfter(hoy)
          ).toList();
          break;
        case 'semana':
          final semana = now.subtract(const Duration(days: 7));
          ventasFiltradas = ventasFiltradas.where((venta) =>
              venta.fechaVenta.isAfter(semana)
          ).toList();
          break;
        case 'mes':
          final mes = DateTime(now.year, now.month, 1);
          ventasFiltradas = ventasFiltradas.where((venta) =>
              venta.fechaVenta.isAfter(mes)
          ).toList();
          break;
      }
    }

    return ventasFiltradas;
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Estado de la venta:'),
            DropdownButtonFormField<String>(
              value: _filtroEstado,
              items: const [
                DropdownMenuItem(value: 'todos', child: Text('Todos')),
                DropdownMenuItem(value: 'completada', child: Text('Completadas')),
                DropdownMenuItem(value: 'cancelada', child: Text('Canceladas')),
              ],
              onChanged: (value) {
                setState(() {
                  _filtroEstado = value ?? 'todos';
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            const Text('Periodo:'),
            DropdownButtonFormField<String>(
              value: _filtroFecha,
              items: const [
                DropdownMenuItem(value: 'todos', child: Text('Todos')),
                DropdownMenuItem(value: 'hoy', child: Text('Hoy')),
                DropdownMenuItem(value: 'semana', child: Text('Ultima semana')),
                DropdownMenuItem(value: 'mes', child: Text('Este mes')),
              ],
              onChanged: (value) {
                setState(() {
                  _filtroFecha = value ?? 'todos';
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _getColorEstado(String estado) {
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

  String _getTextoEstado(String estado) {
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
}