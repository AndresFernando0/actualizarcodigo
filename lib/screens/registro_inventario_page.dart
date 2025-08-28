import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import '../models/inventario.dart';
import '../services/inventario_service.dart';

class RegistroInventarioPage extends StatefulWidget {
  const RegistroInventarioPage({super.key});

  @override
  State<RegistroInventarioPage> createState() => _RegistroInventarioPageState();
}

class _RegistroInventarioPageState extends State<RegistroInventarioPage> {
  final InventarioService _inventarioService = InventarioService();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController precioController = TextEditingController();
  final TextEditingController imeiController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "es_HN");
  List<Inventario> productos = [];
  String? idEdicion;
  bool _guardando = false;

  @override
  void dispose() {
    nombreController.dispose();
    precioController.dispose();
    imeiController.dispose();
    super.dispose();
  }

  void _escanearCodigo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              AppBar(
                title: const Text('Escanear Codigo IMEI'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              Expanded(
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: MobileScannerController(
                        facing: CameraFacing.back,
                        torchEnabled: false,
                      ),
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty) {
                          setState(() {
                            imeiController.text = barcodes.first.rawValue ?? '';
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('IMEI escaneado: ${barcodes.first.rawValue}'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                    ),
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Coloque el código IMEI dentro del marco para escanear',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _agregarALista() {
    if (nombreController.text.isEmpty || precioController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 10),
              Text('Por favor completa los campos requeridos'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // VALIDAR IMEI SI SE ESCRIBIO
    if (imeiController.text.isNotEmpty && imeiController.text.length != 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 10),
              Text('El IMEI debe tener exactamente 15 digitos'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      final String precioLimpio =
          precioController.text.replaceAll('L. ', '').replaceAll(',', '').trim();

      final double precioDouble = double.tryParse(precioLimpio) ?? 0.0;

      final producto = Inventario(
        id: idEdicion ?? DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: nombreController.text.trim(),
        imei: imeiController.text.trim(),
        precio: precioDouble,
        stock: 1,
        disponible: true,
        fecha: DateTime.now(),
      );

      print('📝 Agregando a lista: ${producto.nombre} - L. ${producto.precio}');

      if (idEdicion != null) {
        // ACTUALIZAR PRODUCTO EXISTENTE
        final index = productos.indexWhere((p) => p.id == idEdicion);
        if (index >= 0) {
          productos[index] = producto;
        }
      } else {
        // AGREGAR NUEVO PRODUCTO
        productos.add(producto);
      }
      
      _limpiarCampos();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(idEdicion != null ? 'Producto actualizado en la lista' : 'Producto agregado a la lista'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _limpiarCampos() {
    nombreController.clear();
    precioController.clear();
    imeiController.clear();
    idEdicion = null;
  }

  void _editarProducto(int index) {
    final producto = productos[index];
    setState(() {
      nombreController.text = producto.nombre;
      precioController.text = 'L. ${_currencyFormat.format(producto.precio)}';
      imeiController.text = producto.imei;
      idEdicion = producto.id;
      productos.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.edit, color: Colors.white),
            SizedBox(width: 10),
            Text('Producto cargado para edicion'),
          ],
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String formatNumber(String value) {
    if (value.isEmpty) return '';
    final number = double.tryParse(value.replaceAll(',', '')) ?? 0;
    final parts = number.toInt().toString().split('');
    String result = '';
    for (int i = parts.length - 1, count = 0; i >= 0; i--, count++) {
      if (count > 0 && count % 3 == 0) {
        result = ',' + result;
      }
      result = parts[i] + result;
    }
    return result;
  }

  Future<void> _guardarProductos() async {
    if (_guardando) return;

    if (productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 10),
              Text('Agregue productos a la lista antes de guardar'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _guardando = true;
      });

      final productosParaGuardar = List<Inventario>.from(productos);
      final cantidadProductos = productosParaGuardar.length;

      print('🔄 Iniciando guardado de $cantidadProductos productos...');

      await _inventarioService.guardarInventario(productosParaGuardar);

      setState(() {
        productos = [];
        _limpiarCampos();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text(cantidadProductos == 1
                    ? '¡1 producto guardado exitosamente!'
                    : '¡$cantidadProductos productos guardados exitosamente!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                SizedBox(width: 10),
                Text('¡Guardado Exitoso!'),
              ],
            ),
            content: Text(cantidadProductos == 1
                ? 'Se ha guardado 1 producto correctamente en el inventario.'
                : 'Se han guardado $cantidadProductos productos correctamente en el inventario.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('Continuar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ Error al guardar productos: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Error al guardar los productos: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  Widget _buildActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 400) {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _escanearCodigo,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Escanear IMEI'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _agregarALista,
                  icon: const Icon(Icons.add),
                  label: Text(idEdicion != null ? 'Actualizar en Lista' : 'Agregar a Lista'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _escanearCodigo,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Escanear IMEI'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _agregarALista,
                  icon: const Icon(Icons.add),
                  label: Text(idEdicion != null ? 'Actualizar' : 'Agregar a Lista'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildProductoCard(Inventario producto, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
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
            if (producto.imei.isNotEmpty) Text('IMEI: ${producto.imei}'),
            Text('Precio: L. ${_currencyFormat.format(producto.precio)}'),
          ],
        ),
        trailing: SizedBox(
          width: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => _editarProducto(index),
                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                tooltip: 'Editar',
              ),
              IconButton(
                onPressed: () => setState(() => productos.removeAt(index)),
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                tooltip: 'Eliminar',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Inventario'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con fecha
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nuevo Registro',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // FORMULARIO
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Producto *',
                hintText: 'Ej: Samsung Galaxy S20',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_android),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: precioController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final cleanText = newValue.text.replaceAll(',', '');
                  if (cleanText.isEmpty) return newValue;

                  final formatted = formatNumber(cleanText);
                  return TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }),
              ],
              decoration: const InputDecoration(
                labelText: 'Precio *',
                hintText: '0.00',
                prefixText: 'L. ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: imeiController,
              maxLength: 15,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'IMEI (Opcional)',
                hintText: 'Escanear o ingresar manualmente',
                counterText: '15 digitos maximo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fingerprint),
              ),
            ),
            const SizedBox(height: 20),

            _buildActionButtons(),
            const SizedBox(height: 24),

            // LISTA DE PRODUCTOS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lista de Productos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${productos.length} ${productos.length == 1 ? 'producto' : 'productos'}',
                    style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              height: MediaQuery.of(context).size.height * 0.3,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: productos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          Text(
                            'No hay productos en la lista',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Agregue productos usando el formulario',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: productos.length,
                      itemBuilder: (context, index) {
                        return _buildProductoCard(productos[index], index);
                      },
                    ),
            ),
            const SizedBox(height: 20),

            // BOTON GUARDAR
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: productos.isNotEmpty && !_guardando ? _guardarProductos : null,
                icon: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_guardando ? 'Guardando...' : 'Guardar en Inventario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: productos.isNotEmpty ? Colors.blue : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}