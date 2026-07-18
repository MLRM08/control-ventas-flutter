import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/autenticacion_provider.dart';
import '../providers/ventas_cobros_provider.dart';

class PantallaRegistroTransaccion extends StatefulWidget {
  const PantallaRegistroTransaccion({super.key});

  @override
  State<PantallaRegistroTransaccion> createState() =>
      _PantallaRegistroTransaccionState();
}

class _PantallaRegistroTransaccionState
    extends State<PantallaRegistroTransaccion> {
  final _montoCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  String? _categoriaSeleccionada;
  String? _metodoSeleccionada;
  String _tipoTransaccion = 'Venta';

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AutenticacionProvider>(context);
    final datos = Provider.of<VentasCobrosProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Transacción'),
        backgroundColor: Colors.yellow,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Nueva Operación',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Venta 🛍️'),
                            selected: _tipoTransaccion == 'Venta',
                            selectedColor: Colors.green.shade200,
                            onSelected: (bool selected) {
                              if (selected)
                                setState(() => _tipoTransaccion = 'Venta');
                            },
                          ),
                          const SizedBox(width: 16),
                          ChoiceChip(
                            label: const Text('Cobro 💵'),
                            selected: _tipoTransaccion == 'Cobro',
                            selectedColor: Colors.blue.shade200,
                            onSelected: (bool selected) {
                              if (selected)
                                setState(() => _tipoTransaccion = 'Cobro');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _montoCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monto (\$)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _notaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Cliente / Detalle',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      StreamBuilder<QuerySnapshot>(
                        stream: datos.obtenerCategorias(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return const CircularProgressIndicator();
                          var items = snapshot.data!.docs
                              .map((doc) => doc['nombre'].toString())
                              .toList();
                          return DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _categoriaSeleccionada,
                            hint: const Text('Línea de Producto / Servicio'),
                            items: items
                                .map(
                                  (val) => DropdownMenuItem(
                                    value: val,
                                    child: Text(
                                      val,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _categoriaSeleccionada = val),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      StreamBuilder<QuerySnapshot>(
                        stream: datos.obtenerMetodosPago(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return const CircularProgressIndicator();
                          var items = snapshot.data!.docs
                              .map((doc) => doc['nombre'].toString())
                              .toList();
                          return DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _metodoSeleccionada,
                            hint: const Text('Forma de Pago'),
                            items: items
                                .map(
                                  (val) => DropdownMenuItem(
                                    value: val,
                                    child: Text(
                                      val,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _metodoSeleccionada = val),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _tipoTransaccion == 'Venta'
                              ? Colors.green.shade300
                              : Colors.blue.shade300,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final monto = double.tryParse(_montoCtrl.text);
                          if (monto != null &&
                              _categoriaSeleccionada != null &&
                              _metodoSeleccionada != null) {
                            await datos.guardarTransaccion(
                              uidUsuario: auth.usuario!.uid,
                              emailUsuario: auth.usuario!.email ?? 'Sin Correo',
                              monto: monto,
                              category: _categoriaSeleccionada!,
                              metodoPago: _metodoSeleccionada!,
                              nota: _notaCtrl.text,
                              tipo: _tipoTransaccion,
                            );
                            _montoCtrl.clear();
                            _notaCtrl.clear();
                            setState(() {
                              _categoriaSeleccionada = null;
                              _metodoSeleccionada = null;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '¡$_tipoTransaccion guardada con éxito!',
                                  ),
                                ),
                              );
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: Text(
                          'Guardar $_tipoTransaccion',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
