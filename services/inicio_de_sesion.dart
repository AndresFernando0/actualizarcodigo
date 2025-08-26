import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InicioDeSesion {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> iniciarSesion(String usuario, String contrasena) async {
    try {
      final QuerySnapshot result = await _firestore
          .collection('usuario')
          .where('Usuario', isEqualTo: usuario)
          .where('Contraseña', isEqualTo: contrasena)
          .get();

      if (result.docs.isNotEmpty) {
        final doc = result.docs.first.data() as Map<String, dynamic>;

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('usuario', usuario);
        await prefs.setString('nombre', doc['Nombre'] ?? '');
        await prefs.setString('rol', doc['Rol'] ?? '');

        return true;
      }

      return false;
    } catch (e) {
      print('Error al iniciar sesión: $e');
      return false;
    }
  }

  Future<void> cerrarSesion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
  }
}

Future<bool> estaLogueado() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}
