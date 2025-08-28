import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventario.dart';

class InventarioCard extends StatelessWidget {
  final Inventario inventario;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const InventarioCard({
    super.key,
    required this.inventario,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat("#,##0.00", "es_HN");
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: inventario.disponible ? 2 : 1,
      color: inventario.disponible ? null : Colors.grey.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icono del producto
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: inventario.disponible 
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: inventario.disponible 
                      ? Border.all(color: Colors.green.withOpacity(0.3))
                      : Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Icon(
                  Icons.phone_android,
                  color: inventario.disponible ? Colors.green : Colors.red,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              
              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inventario.nombre,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: inventario.disponible ? null : TextDecoration.lineThrough,
                        color: inventario.disponible ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (inventario.imei.isNotEmpty)
                      Text(
                        'IMEI: ${inventario.imei}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Registrado: ${DateFormat('dd/MM/yyyy').format(inventario.fecha)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (!inventario.disponible) ...[
                      const SizedBox(height: 4),
                      if (inventario.vendidoPor != null)
                        Text(
                          'Vendido por: ${inventario.vendidoPor}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (inventario.numeroVenta != null)
                        Text(
                          'Venta: ${inventario.numeroVenta}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              
              // Precio y estado
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'L. ${currencyFormat.format(inventario.precio)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: inventario.disponible ? Colors.green : Colors.grey,
                      decoration: inventario.disponible ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: inventario.disponible ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      inventario.disponible ? 'DISPONIBLE' : 'VENDIDO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if ((onEdit != null || onDelete != null) && inventario.disponible) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onEdit != null)
                          IconButton(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                            tooltip: 'Editar',
                          ),
                        if (onDelete != null)
                          IconButton(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                            tooltip: 'Eliminar',
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}