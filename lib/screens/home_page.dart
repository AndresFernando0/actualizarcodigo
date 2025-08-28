import 'inventario_page.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'registro_inventario_page.dart';
import 'registro_ventas_page.dart'; // Agregamos esta importación
import 'login.dart';
import 'ajustes.dart';
import 'historial_ventas.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 30),
            const Text(
              'Menú Principal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuGrid(context),
            const SizedBox(height: 30),
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Originales CellStore',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: const Color(0xFF4CAF50),
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_outlined),
          onPressed: () => _showLogoutDialog(context),
          tooltip: 'Cerrar sesión',
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF4CAF50).withOpacity(0.1),
              const Color(0xFF66BB6A).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.dashboard_outlined,
              size: 32,
              color: Color(0xFF2E7D32),
            ),
            const SizedBox(height: 12),
            FutureBuilder<String>(
              future: usuarioLogueado(),
              builder: (context, snapshot) {
                final nombre = snapshot.data ?? 'Invitado';
                return Text(
                  '¡Bienvenido $nombre!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              'Gestiona tu inventario y ventas de forma eficiente',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF2E7D32).withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatCard(
                    'Productos', '25', Icons.inventory_2, Colors.blue),
                const SizedBox(width: 12),
                _buildStatCard('Ventas Hoy', '12', Icons.trending_up,
                    const Color(0xFF4CAF50)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.65,
      children: [
        _buildMenuCard(
          context,
          'Ventas',
          'Registra nuevas ventas',
          Icons.point_of_sale_outlined,
          Colors.blue,
          () => _navigateToPage(context, const RegistroVentasScreen()), // Corregido
        ),
        _buildMenuCard(
          context,
          'Registro de Inventario',
          'Añade nuevos productos',
          Icons.add_box_outlined,
          const Color(0xFF4CAF50),
          () => _navigateToPage(context, const RegistroInventarioPage()), 
        ),
        _buildMenuCard(
          context,
          'Historial de Ventas',
          'Ventas realizadas',
          Icons.history_outlined,
          Colors.green,
          () => _navigateToPage(context, const HistorialVentasScreen()),
        ),
        _buildMenuCard(
          context,
          'Inventario',
          'Ver productos disponibles',
          Icons.inventory_2_outlined,
          Colors.orange,
          () => _navigateToPage(context, const InventarioPage1()),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Accesos Rápidos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickAction(
                'Venta Rápida',
                Icons.flash_on,
                const Color(0xFF4CAF50),
                () => _navigateToPage(context, const RegistroVentasScreen()),
              ),
              _buildQuickAction(
                'Buscar',
                Icons.search,
                const Color(0xFF2196F3),
                () => _showComingSoon(context, 'Función de búsqueda'),
              ),
              _buildQuickAction(
                'Reportes',
                Icons.analytics_outlined,
                const Color(0xFFFF9800),
                () => _showComingSoon(context, 'Reportes y análisis'),
              ),
              _buildQuickAction(
                'Ajustes',
                Icons.settings,
                const Color(0xFF757575),
                () => _navigateToPage(context, const SettingsScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  Future<String> usuarioLogueado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nombre') ?? 'Invitado';
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_outlined),
            SizedBox(width: 8),
            Text('Cerrar Sesión'),
          ],
        ),
        content: const Text('¿Estas seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              await _clearSession();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => PantallaLogin()),
                (route) => false,
              );
            },
            child: const Text('Sí'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text('$feature próximamente disponible'),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}