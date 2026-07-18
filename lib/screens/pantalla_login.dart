import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/autenticacion_provider.dart';
import 'pantalla_dashboard.dart';

class GestorPantallas extends StatelessWidget {
  const GestorPantallas({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AutenticacionProvider>(context);
    return authProvider.usuario != null
        ? const PantallaDashboard()
        : const PantallaLogin();
  }
}

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _esRegistro = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AutenticacionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_esRegistro ? 'Crear Cuenta Comercial' : 'Iniciar Sesión'),
        backgroundColor: Colors.yellow,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront, size: 80, color: Colors.orange),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Correo Corporativo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () async {
                    String? error;
                    if (_esRegistro) {
                      error = await auth.registrar(
                        _emailCtrl.text.trim(),
                        _passCtrl.text.trim(),
                      );
                    } else {
                      error = await auth.iniciarSesion(
                        _emailCtrl.text.trim(),
                        _passCtrl.text.trim(),
                      );
                    }
                    if (error != null && context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error)));
                    }
                  },
                  child: Text(
                    _esRegistro ? 'Registrarse' : 'Ingresar al Sistema',
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _esRegistro = !_esRegistro),
                  child: Text(
                    _esRegistro
                        ? '¿Ya tienes cuenta? Inicia sesión'
                        : '¿No tienes cuenta? Regístrate aquí',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
