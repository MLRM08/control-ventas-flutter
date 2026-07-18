import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/autenticacion_provider.dart';
import 'pantalla_registro.dart';
import 'pantalla_historial.dart';

class PantallaDashboard extends StatelessWidget {
  const PantallaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AutenticacionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú de Operaciones 🏪'),
        backgroundColor: Colors.yellow,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.cerrarSesion(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance,
                    size: 70,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '¡Hola, bienvenido al sistema!\n${auth.usuario?.email}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 40),

                  _crearBotonMenu(
                    context: context,
                    titulo: 'Registrar Ventas y Cobros',
                    subtitulo: 'Añadir nuevas transacciones diarias al sistema',
                    icono: Icons.add_circle_outline,
                    color: Colors.green.shade600,
                    destino: const PantallaRegistroTransaccion(),
                  ),
                  const SizedBox(height: 20),

                  _crearBotonMenu(
                    context: context,
                    titulo: 'Consultar Historial y Totales',
                    subtitulo:
                        'Ver movimientos detallados, resúmenes diarios y modo admin',
                    icono: Icons.bar_chart_outlined,
                    color: Colors.blue.shade600,
                    destino: const PantallaHistorialTotales(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _crearBotonMenu({
    required BuildContext context,
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Color color,
    required Widget destino,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destino),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icono, size: 35, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
