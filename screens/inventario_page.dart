import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventario.dart';
import '../services/inventario_service.dart';
import '../widgets/inventario_card.dart';

enum OrdenTipo { precioAsc, precioDesc, fechaReciente, fechaAntigua }

class InventarioPage1 extends StatefulWidget {
  const InventarioPage1({super.key});

  @override
  State<InventarioPage1> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage1> {
  final InventarioService _inventarioService = InventarioService();

  OrdenTipo _ordenSeleccionado = OrdenTipo.fechaReciente;

  void _confirmarEliminacion(BuildContext context, Inventario item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
            '¿Estas seguro de que deseas eliminar el producto "${item.nombre}"?'),
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
                    const SnackBar(
                      content: Text('Producto eliminado exitosamente'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          PopupMenuButton<OrdenTipo>(
            icon: const Icon(Icons.filter_list),
            onSelected: _cambiarOrden,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: OrdenTipo.precioAsc,
                child: Text("Precio más bajo"),
              ),
              const PopupMenuItem(
                value: OrdenTipo.precioDesc,
                child: Text("Precio más alto"),
              ),
              const PopupMenuItem(
                value: OrdenTipo.fechaReciente,
                child: Text("Fecha más reciente"),
              ),
              const PopupMenuItem(
                value: OrdenTipo.fechaAntigua,
                child: Text("Fecha más antigua"),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Inventario>>(
        stream: _inventarioService.getInventario(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var inventario = snapshot.data;
          if (inventario == null || inventario.isEmpty) {
            return const Center(child: Text('No hay productos registrados'));
          }

          inventario.sort((a, b) {
            switch (_ordenSeleccionado) {
              case OrdenTipo.precioAsc: 
                return a.total.compareTo(b.total);
              case OrdenTipo.precioDesc: 
                return b.total.compareTo(a.total);
              case OrdenTipo.fechaReciente: 
                return b.fecha.compareTo(a.fecha);
              case OrdenTipo.fechaAntigua: 
                return a.fecha.compareTo(b.fecha);
            }
          });

          return ListView.builder(
            itemCount: inventario.length,
            itemBuilder: (context, index) {
              final item = inventario[index];
              return InventarioCard(
                inventario: item,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Detalles del Producto'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Artículo: ${item.nombre}"),
                            Text("IMEI: ${item.imei}"),
                            Text(
                              "Total: L. ${NumberFormat("#,##0.00", "es_HN").format(item.total)}",
                            ),
                            Text(
                              "Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(item.fecha)}",
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmarEliminacion(context, item);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}