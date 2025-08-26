import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventario.dart';

class InventarioCard extends StatelessWidget {
  final Inventario inventario;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "en_US");

  InventarioCard({
    super.key,
    required this.inventario,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalFormateado = _currencyFormat.format(inventario.total.toDouble());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(
          inventario.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "IMEI: ${inventario.imei}\nTotal: L. $totalFormateado\nFecha: ${DateFormat('dd/MM/yyyy HH:mm').format(inventario.fecha)}",
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}