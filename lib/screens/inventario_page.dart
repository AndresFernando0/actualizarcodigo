import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventario.dart';
import '../services/inventario_service.dart';

enum OrdenTipo { precioAsc, precioDesc, fechaReciente, fechaAntigua, disponible, vendido }
enum FiltroTipo { todos, disponibles, vendidos }

class InventarioPage1 extends StatefulWidget {
  const InventarioPage1({super.key});

  @override
  State<InventarioPage1> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage1> {
  final InventarioService _inventarioService = InventarioService();
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "es_HN");

  OrdenTipo _ordenSeleccionado = OrdenTipo.fechaReciente;
  FiltroTipo _filtroSeleccionado = FiltroTipo.todos;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmarEliminacion(BuildContext context, Inventario item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 10),
            Text('Confirmar Eliminación'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Esta seguro de que desea eliminar el producto "${item.nombre}"?'),
            const SizedBox(height: 8),
            if (!item.disponible)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Nota: Este producto ya fue vendido. Eliminarlo no afectara la venta.',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _inventarioService.eliminarItemInventario(item.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 10),
                          Text('Producto "${item.nombre}" eliminado exitosamente'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar el producto: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _cambiarOrden(OrdenTipo tipo) {
    setState(() {
      _ordenSeleccionado = tipo;
    });
  }

  void _cambiarFiltro(FiltroTipo tipo) {
    setState(() {
      _filtroSeleccionado = tipo;
    });
  }

  List<Inventario> _aplicarFiltrosYOrden(List<Inventario> inventario) {
    // APLICAR LOS FILTROS
    List<Inventario> inventarioFiltrado = List.from(inventario);

    // FILTRO POR BUSQUEDA
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      inventarioFiltrado = inventarioFiltrado.where((item) =>
          item.nombre.toLowerCase().contains(searchTerm) ||
          item.imei.contains(searchTerm)
      ).toList();
    }

    // FILTRO POR DISPONIBILIDAD
    switch (_filtroSeleccionado) {
      case FiltroTipo.disponibles:
        inventarioFiltrado = inventarioFiltrado.where((item) => item.disponible).toList();
        break;
      case FiltroTipo.vendidos:
        inventarioFiltrado = inventarioFiltrado.where((item) => !item.disponible).toList();
        break;
      case FiltroTipo.todos:
        break;
    }

    // APLICAR ORDEN
    inventarioFiltrado.sort((a, b) {
      switch (_ordenSeleccionado) {
        case OrdenTipo.precioAsc:
          return a.precio.compareTo(b.precio);
        case OrdenTipo.precioDesc:
          return b.precio.compareTo(a.precio);
        case OrdenTipo.fechaReciente:
          return b.fecha.compareTo(a.fecha);
        case OrdenTipo.fechaAntigua:
          return a.fecha.compareTo(b.fecha);
        case OrdenTipo.disponible:
          return b.disponible ? 1 : -1;
        case OrdenTipo.vendido:
          return a.disponible ? 1 : -1;
      }
    });

    return inventarioFiltrado;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              if (value.startsWith('orden_')) {
                final ordenStr = value.substring(6);
                final orden = OrdenTipo.values.firstWhere(
                  (e) => e.toString().split('.').last == ordenStr
                );
                _cambiarOrden(orden);
              } else if (value.startsWith('filtro_')) {
                final filtroStr = value.substring(7);
                final filtro = FiltroTipo.values.firstWhere(
                  (e) => e.toString().split('.').last == filtroStr
                );
                _cambiarFiltro(filtro);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: '',
                enabled: false,
                child: Text('FILTROS', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const PopupMenuItem(
                value: 'filtro_todos',
                child: Text('Mostrar todos'),
              ),
              const PopupMenuItem(
                value: 'filtro_disponibles',
                child: Text('Solo disponibles'),
              ),
              const PopupMenuItem(
                value: 'filtro_vendidos',
                child: Text('Solo vendidos'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: '',
                enabled: false,
                child: Text('ORDENAR POR', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const PopupMenuItem(
                value: 'orden_precioAsc',
                child: Text('Precio más bajo'),
              ),
              const PopupMenuItem(
                value: 'orden_precioDesc',
                child: Text('Precio más alto'),
              ),
              const PopupMenuItem(
                value: 'orden_fechaReciente',
                child: Text('Fecha más reciente'),
              ),
              const PopupMenuItem(
                value: 'orden_fechaAntigua',
                child: Text('Fecha más antigua'),
              ),
              const PopupMenuItem(
                value: 'orden_disponible',
                child: Text('Disponibles primero'),
              ),
              const PopupMenuItem(
                value: 'orden_vendido',
                child: Text('Vendidos primero'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // BARRA DE BUSQUEDA Y ESTADISTICA
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre o IMEI',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                _buildEstadisticasHeader(),
              ],
            ),
          ),
          
          // LISTA DE INVENTARIO
          Expanded(
            child: StreamBuilder<List<Inventario>>(
              stream: _inventarioService.getInventario(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
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

                var inventario = snapshot.data ?? [];
                inventario = _aplicarFiltrosYOrden(inventario);

                if (inventario.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'No se encontraron productos'
                              : 'No hay productos registrados',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        if (_searchController.text.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            child: const Text('Limpiar busqueda'),
                          ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: inventario.length,
                    itemBuilder: (context, index) {
                      final item = inventario[index];
                      return _buildInventarioCard(item);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticasHeader() {
    return StreamBuilder<List<Inventario>>(
      stream: _inventarioService.getInventario(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final inventario = snapshot.data!;
        final disponibles = inventario.where((item) => item.disponible).length;
        final vendidos = inventario.length - disponibles;
        final valorTotal = inventario
            .where((item) => item.disponible)
            .fold(0.0, (sum, item) => sum + item.precio);

        return Container(
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
                  'Disponibles',
                  '$disponibles',
                  'productos',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Vendidos',
                  '$vendidos',
                  'productos',
                  Icons.shopping_cart,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Valor Total',
                  'L. ${_currencyFormat.format(valorTotal)}',
                  'disponible',
                  Icons.attach_money,
                  Colors.blue,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String titulo, String valor, String subtitulo, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Text(valor, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold)),
        Text(subtitulo, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildInventarioCard(Inventario item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: item.disponible ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.phone_android,
            color: item.disponible ? Colors.green : Colors.red,
            size: 30,
          ),
        ),
        title: Text(
          item.nombre,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: item.disponible ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IMEI: ${item.imei}'),
            Text('Registrado: ${DateFormat('dd/MM/yyyy').format(item.fecha)}'),
            if (!item.disponible && item.vendidoPor != null) ...[
              Text('Vendido por: ${item.vendidoPor}', style: const TextStyle(color: Colors.red)),
              if (item.numeroVenta != null)
                Text('Venta: ${item.numeroVenta}', style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'L. ${_currencyFormat.format(item.precio)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: item.disponible ? Colors.green : Colors.grey,
                decoration: item.disponible ? null : TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: item.disponible ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.disponible ? 'DISPONIBLE' : 'VENDIDO',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        onTap: () => _mostrarDetallesProducto(item),
      ),
    );
  }

  void _mostrarDetallesProducto(Inventario item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.phone_android,
              color: item.disponible ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(item.nombre)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleRow('Producto', item.nombre),
              _buildDetalleRow('IMEI', item.imei),
              _buildDetalleRow('Precio', 'L. ${_currencyFormat.format(item.precio)}'),
              _buildDetalleRow('Stock', '${item.stock}'),
              _buildDetalleRow('Estado', item.disponible ? 'Disponible' : 'Vendido'),
              _buildDetalleRow('Fecha Registro', DateFormat('dd/MM/yyyy HH:mm').format(item.fecha)),
              if (item.fechaActualizacion != null)
                _buildDetalleRow('Ultima Actualizacion', DateFormat('dd/MM/yyyy HH:mm').format(item.fechaActualizacion!)),
              if (!item.disponible) ...[
                const Divider(),
                const Text('Informacion de Venta:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                if (item.fechaVenta != null)
                  _buildDetalleRow('Fecha Venta', DateFormat('dd/MM/yyyy HH:mm').format(item.fechaVenta!)),
                if (item.vendidoPor != null)
                  _buildDetalleRow('Vendido por', item.vendidoPor!),
                if (item.numeroVenta != null)
                  _buildDetalleRow('Numero de Venta', item.numeroVenta!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (item.disponible)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmarEliminacion(context, item);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
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
}