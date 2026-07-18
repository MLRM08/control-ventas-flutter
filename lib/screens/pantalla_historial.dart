import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/autenticacion_provider.dart';
import '../providers/ventas_cobros_provider.dart';

class PantallaHistorialTotales extends StatefulWidget {
  const PantallaHistorialTotales({super.key});

  @override
  State<PantallaHistorialTotales> createState() =>
      _PantallaHistorialTotalesState();
}

class _PantallaHistorialTotalesState extends State<PantallaHistorialTotales> {
  bool _modoAdmin = false;
  String? _usuarioSeleccionadoAdmin;

  Map<String, Map<String, double>> _calcularTotalesPorDia(
    List<QueryDocumentSnapshot> docs,
  ) {
    Map<String, Map<String, double>> totales = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final double monto = (data['monto'] as num).toDouble();
      final String tipo = data['tipo']?.toString() ?? 'Venta';

      DateTime fechaObj = DateTime.now();
      if (data['fecha'] != null) {
        fechaObj = (data['fecha'] as Timestamp).toDate();
      }
      final String fechaFormateada =
          "${fechaObj.year}-${fechaObj.month.toString().padLeft(2, '0')}-${fechaObj.day.toString().padLeft(2, '0')}";

      if (!totales.containsKey(fechaFormateada)) {
        totales[fechaFormateada] = {'Venta': 0.0, 'Cobro': 0.0};
      }
      totales[fechaFormateada]![tipo] =
          (totales[fechaFormateada]![tipo] ?? 0.0) + monto;
    }
    return totales;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AutenticacionProvider>(context);
    final datos = Provider.of<VentasCobrosProvider>(context);

    final filtroAEscuchar = (_modoAdmin && _usuarioSeleccionadoAdmin != null)
        ? _usuarioSeleccionadoAdmin!
        : auth.usuario!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial y Estadísticas'),
        backgroundColor: Colors.yellow,
        actions: [
          Row(
            children: [
              const Text(
                "Modo Admin",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Switch(
                value: _modoAdmin,
                onChanged: (val) {
                  setState(() {
                    _modoAdmin = val;
                    if (!val) _usuarioSeleccionadoAdmin = null;
                  });
                },
              ),
              const SizedBox(width: 10),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_modoAdmin) ...[
              Card(
                color: Colors.blue.shade50,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: StreamBuilder<List<String>>(
                    stream: datos.obtenerTodosLosUsuariosComerciales(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Text("Buscando vendedores...");
                      final listaUsuarios = snapshot.data!;
                      return Row(
                        children: [
                          const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Auditar Vendedor: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _usuarioSeleccionadoAdmin,
                              hint: const Text(
                                "Selecciona el correo de un vendedor",
                              ),
                              items: listaUsuarios
                                  .map(
                                    (correo) => DropdownMenuItem(
                                      value: correo,
                                      child: Text(
                                        correo,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _usuarioSeleccionadoAdmin = val;
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Movimientos Registrados',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: datos.obtenerTransaccionesUsuario(
                                  filtroAEscuchar,
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting)
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty)
                                    return const Center(
                                      child: Text(
                                        'Sin movimientos registrados.',
                                      ),
                                    );

                                  return ListView.builder(
                                    itemCount: snapshot.data!.docs.length,
                                    itemBuilder: (context, index) {
                                      var doc = snapshot.data!.docs[index];
                                      final tipo = doc['tipo'] ?? 'Venta';
                                      final esVenta = tipo == 'Venta';

                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: esVenta
                                              ? Colors.green.shade100
                                              : Colors.blue.shade100,
                                          child: Icon(
                                            esVenta
                                                ? Icons.arrow_upward
                                                : Icons.arrow_downward,
                                            color: esVenta
                                                ? Colors.green.shade700
                                                : Colors.blue.shade700,
                                          ),
                                        ),
                                        title: Text(
                                          '\$${doc['monto']} - ${doc['categoria']}',
                                        ),
                                        subtitle: Text(
                                          'Operación: $tipo | Pago: ${doc['metodoPago']}\nDetalle: ${doc['nota']}',
                                        ),
                                        isThreeLine: true,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    flex: 2,
                    child: Card(
                      color: Colors.green.shade50,
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Resumen Comercial Diario 📊',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Divider(),
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: datos.obtenerTransaccionesUsuario(
                                  filtroAEscuchar,
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting)
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty)
                                    return const Center(
                                      child: Text(
                                        'Sin transacciones procesadas.',
                                      ),
                                    );

                                  final totalesPorDia = _calcularTotalesPorDia(
                                    snapshot.data!.docs,
                                  );

                                  return ListView(
                                    children: totalesPorDia.entries.map((
                                      entry,
                                    ) {
                                      final ventasDia =
                                          entry.value['Venta'] ?? 0.0;
                                      final cobrosDia =
                                          entry.value['Cobro'] ?? 0.0;

                                      return Card(
                                        elevation: 1,
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                entry.key,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const Divider(height: 10),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  const Text(
                                                    "Ventas:",
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    '\$${ventasDia.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  const Text(
                                                    "Cobros:",
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    '\$${cobrosDia.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
