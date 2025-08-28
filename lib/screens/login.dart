import 'package:flutter/material.dart';
import '../services/inicio_de_sesion.dart';
import 'home_page.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final TextEditingController _controladorUsuario = TextEditingController();
  final TextEditingController _controladorContrasena = TextEditingController();
  final InicioDeSesion _servicioInicioSesion = InicioDeSesion();

  bool _cargando = false;

  @override
  void dispose() {
    _controladorUsuario.dispose();
    _controladorContrasena.dispose();
    super.dispose();
  }

  void _iniciarSesion() async {
    setState(() {
      _cargando = true;
    });

    String usuario = _controladorUsuario.text.trim();
    String contrasena = _controladorContrasena.text.trim();

    if (usuario.isEmpty || contrasena.isEmpty) {
      _mostrarMensaje('Por favor, completa todos los campos.');
      setState(() => _cargando = false);
      return;
    }

    bool exito = await _servicioInicioSesion.iniciarSesion(usuario, contrasena);

    setState(() {
      _cargando = false;
    });

    if (exito) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      _mostrarMensaje('Usuario o contraseña incorrectos.');
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Originales CellStore App'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Logo
              Image.asset(
                'assets/originales_cellstore_logo.jpg',
                height: 100, // Ajusta el tamaño según tu logo
              ),
              const SizedBox(height: 32),
              const Text(
                'Bienvenido',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _controladorUsuario,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controladorContrasena,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _cargando ? null : _iniciarSesion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Iniciar sesión',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
