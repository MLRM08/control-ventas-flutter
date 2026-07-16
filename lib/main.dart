import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCnN5F41C68uUvtHHabvZVYMFi0DzVbVtw",
      authDomain: "mi-primera-app-c79e5.firebaseapp.com",
      projectId: "mi-primera-app-c79e5",
      storageBucket: "mi-primera-app-c79e5.firebasestorage.app",
      messagingSenderId: "887442603123",
      appId: "1:887442603123:web:ebdd3f70dbc9b0cf947e06",
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AutenticacionProvider()),
        ChangeNotifierProvider(create: (_) => VentasCobrosProvider()),
      ],
      child: const MiApp(),
    ),
  );
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Control de Ventas y Cobros',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow, primary: Colors.amber),
        useMaterial3: true,
      ),
      home: const GestorPantallas(),
    );
  }
}

// ==========================================
// LÓGICA DE NEGOCIO (PROVIDERS)
// ==========================================

class AutenticacionProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _usuario;

  User? get usuario => _usuario;

  AutenticacionProvider() {
    _auth.authStateChanges().listen((User? user) {
      _usuario = user;
      notifyListeners();
    });
  }

  Future<String?> registrar(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> iniciarSesion(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }
}

class VentasCobrosProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> obtenerCategorias() {
    return _firestore.collection('categorias').snapshots();
  }

  Stream<QuerySnapshot> obtenerMetodosPago() {
    return _firestore.collection('metodos_pago').snapshots();
  }

  // Guardar transacción incluyendo el correo electrónico del vendedor
  Future<void> guardarTransaccion({
    required String uidUsuario,
    required String emailUsuario, 
    required double monto,
    required String categoria,
    required String metodoPago,
    required String nota,
    required String tipo,
  }) async {
    await _firestore.collection('ventas_cobros').add({
      'uidUsuario': uidUsuario,
      'emailUsuario': emailUsuario, 
      'monto': monto,
      'categoria': categoria,
      'metodoPago': metodoPago,
      'nota': nota,
      'tipo': tipo,
      'fecha': DateTime.now(),
    });
  }

  // Cargar transacciones filtrando por UID o por correo electrónico de manera inteligente
  Stream<QuerySnapshot> obtenerTransaccionesUsuario(String filtro) {
    if (filtro.contains('@')) {
      return _firestore
          .collection('ventas_cobros')
          .where('emailUsuario', isEqualTo: filtro)
          .snapshots();
    } else {
      return _firestore
          .collection('ventas_cobros')
          .where('uidUsuario', isEqualTo: filtro)
          .snapshots();
    }
  }

  // Obtiene una lista con los correos electrónicos únicos para el menú del Administrador
  Stream<List<String>> obtenerTodosLosUsuariosComerciales() {
    return _firestore.collection('ventas_cobros').snapshots().map((snapshot) {
      final correos = snapshot.docs.map((doc) {
        final data = doc.data();
        return data.containsKey('emailUsuario') 
            ? doc['emailUsuario'].toString() 
            : doc['uidUsuario'].toString();
      }).toSet().toList();
      return correos;
    });
  }
}

// ==========================================
// CONTROLADOR DE ACCESO
// ==========================================

class GestorPantallas extends StatelessWidget {
  const GestorPantallas({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AutenticacionProvider>(context);
    return authProvider.usuario != null ? const PantallaDashboard() : const PantallaLogin();
  }
}

// ==========================================
// PANTALLAS DEL SISTEMA
// ==========================================

// --- 1. PANTALLA LOGIN ---
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
        backgroundColor: Colors.yellow
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
                  decoration: const InputDecoration(labelText: 'Correo Corporativo', border: OutlineInputBorder())
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl, 
                  obscureText: true, 
                  decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder())
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow, 
                    minimumSize: const Size(double.infinity, 50)
                  ),
                  onPressed: () async {
                    String? error;
                    if (_esRegistro) {
                      error = await auth.registrar(_emailCtrl.text.trim(), _passCtrl.text.trim());
                    } else {
                      error = await auth.iniciarSesion(_emailCtrl.text.trim(), _passCtrl.text.trim());
                    }
                    if (error != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                    }
                  },
                  child: Text(_esRegistro ? 'Registrarse' : 'Ingresar al Sistema'),
                ),
                TextButton(
                  onPressed: () => setState(() => _esRegistro = !_esRegistro),
                  child: Text(_esRegistro ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Regístrate aquí'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- 2. DASHBOARD / MENÚ PRINCIPAL ---
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
          )
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
                  const Icon(Icons.account_balance, size: 70, color: Colors.amber),
                  const SizedBox(height: 10),
                  Text(
                    '¡Hola, bienvenido al sistema!\n${auth.usuario?.email}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
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
                    subtitulo: 'Ver movimientos detallados, resúmenes diarios y modo admin',
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
                    Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitulo, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
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

// --- 3. PANTALLA: REGISTRAR TRANSACCIONES ---
class PantallaRegistroTransaccion extends StatefulWidget {
  const PantallaRegistroTransaccion({super.key});

  @override
  State<PantallaRegistroTransaccion> createState() => _PantallaRegistroTransaccionState();
}

class _PantallaRegistroTransaccionState extends State<PantallaRegistroTransaccion> {
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Nueva Operación', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Venta 🛍️'),
                            selected: _tipoTransaccion == 'Venta',
                            selectedColor: Colors.green.shade200,
                            onSelected: (bool selected) {
                              if (selected) setState(() => _tipoTransaccion = 'Venta');
                            },
                          ),
                          const SizedBox(width: 16),
                          ChoiceChip(
                            label: const Text('Cobro 💵'),
                            selected: _tipoTransaccion == 'Cobro',
                            selectedColor: Colors.blue.shade200,
                            onSelected: (bool selected) {
                              if (selected) setState(() => _tipoTransaccion = 'Cobro');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _montoCtrl, 
                        keyboardType: TextInputType.number, 
                        decoration: const InputDecoration(labelText: 'Monto (\$)', border: OutlineInputBorder())
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _notaCtrl, 
                        decoration: const InputDecoration(labelText: 'Cliente / Detalle', border: OutlineInputBorder())
                      ),
                      const SizedBox(height: 16),
                      
                      StreamBuilder<QuerySnapshot>(
                        stream: datos.obtenerCategorias(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const CircularProgressIndicator();
                          var items = snapshot.data!.docs.map((doc) => doc['nombre'].toString()).toList();
                          return DropdownButtonFormField<String>(
                            isExpanded: true, 
                            value: _categoriaSeleccionada,
                            hint: const Text('Línea de Producto / Servicio'),
                            items: items.map((val) => DropdownMenuItem(value: val, child: Text(val, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) => setState(() => _categoriaSeleccionada = val),
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      StreamBuilder<QuerySnapshot>(
                        stream: datos.obtenerMetodosPago(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const CircularProgressIndicator();
                          var items = snapshot.data!.docs.map((doc) => doc['nombre'].toString()).toList();
                          return DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _metodoSeleccionada,
                            hint: const Text('Forma de Pago'),
                            items: items.map((val) => DropdownMenuItem(value: val, child: Text(val, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) => setState(() => _metodoSeleccionada = val),
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                          );
                        },
                      ),
                      const SizedBox(height: 30),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _tipoTransaccion == 'Venta' ? Colors.green.shade300 : Colors.blue.shade300, 
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final monto = double.tryParse(_montoCtrl.text);
                          if (monto != null && _categoriaSeleccionada != null && _metodoSeleccionada != null) {
                            await datos.guardarTransaccion(
                              uidUsuario: auth.usuario!.uid,
                              emailUsuario: auth.usuario!.email ?? 'Sin Correo', 
                              monto: monto,
                              categoria: _categoriaSeleccionada!,
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
                                SnackBar(content: Text('¡$_tipoTransaccion guardada con éxito!'))
                              );
                              Navigator.pop(context); 
                            }
                          }
                        },
                        child: Text('Guardar $_tipoTransaccion', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      )
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

// --- 4. PANTALLA: HISTORIAL Y REPORTES ---
class PantallaHistorialTotales extends StatefulWidget {
  const PantallaHistorialTotales({super.key});

  @override
  State<PantallaHistorialTotales> createState() => _PantallaHistorialTotalesState();
}

class _PantallaHistorialTotalesState extends State<PantallaHistorialTotales> {
  bool _modoAdmin = false; 
  String? _usuarioSeleccionadoAdmin;

  Map<String, Map<String, double>> _calcularTotalesPorDia(List<QueryDocumentSnapshot> docs) {
    Map<String, Map<String, double>> totales = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final double monto = (data['monto'] as num).toDouble();
      final String tipo = data['tipo']?.toString() ?? 'Venta';
      
      DateTime fechaObj = DateTime.now();
      if (data['fecha'] != null) {
        fechaObj = (data['fecha'] as Timestamp).toDate();
      }
      final String fechaFormateada = "${fechaObj.year}-${fechaObj.month.toString().padLeft(2, '0')}-${fechaObj.day.toString().padLeft(2, '0')}";

      if (!totales.containsKey(fechaFormateada)) {
        totales[fechaFormateada] = {'Venta': 0.0, 'Cobro': 0.0};
      }
      totales[fechaFormateada]![tipo] = (totales[fechaFormateada]![tipo] ?? 0.0) + monto;
    }
    return totales;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AutenticacionProvider>(context);
    final datos = Provider.of<VentasCobrosProvider>(context);

    // Filtra inteligente: si es admin, usa el correo seleccionado; si no, el UID del usuario logueado
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
              const Text("Modo Admin", style: TextStyle(fontWeight: FontWeight.bold)),
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
            // FILTRO ADMINISTRADOR (Muestra correos electrónicos)
            if (_modoAdmin) ...[
              Card(
                color: Colors.blue.shade50,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: StreamBuilder<List<String>>(
                    stream: datos.obtenerTodosLosUsuariosComerciales(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Text("Buscando vendedores...");
                      final listaUsuarios = snapshot.data!;
                      return Row(
                        children: [
                          const Icon(Icons.admin_panel_settings, color: Colors.blue),
                          const SizedBox(width: 10),
                          const Text("Auditar Vendedor: ", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _usuarioSeleccionadoAdmin,
                              hint: const Text("Selecciona el correo de un vendedor"),
                              items: listaUsuarios.map((correo) => DropdownMenuItem(
                                value: correo,
                                child: Text(correo, overflow: TextOverflow.ellipsis),
                              )).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _usuarioSeleccionadoAdmin = val;
                                });
                              },
                            ),
                          )
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
                  // Columna Historial
                  Expanded(
                    flex: 3,
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Movimientos Registrados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const Divider(),
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: datos.obtenerTransaccionesUsuario(filtroAEscuchar),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Sin movimientos registrados.'));
                                  
                                  return ListView.builder(
                                    itemCount: snapshot.data!.docs.length,
                                    itemBuilder: (context, index) {
                                      var doc = snapshot.data!.docs[index];
                                      final tipo = doc['tipo'] ?? 'Venta';
                                      final esVenta = tipo == 'Venta';

                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: esVenta ? Colors.green.shade100 : Colors.blue.shade100,
                                          child: Icon(
                                            esVenta ? Icons.arrow_upward : Icons.arrow_downward, 
                                            color: esVenta ? Colors.green.shade700 : Colors.blue.shade700
                                          ),
                                        ),
                                        title: Text('\$${doc['monto']} - ${doc['categoria']}'),
                                        subtitle: Text('Operación: $tipo | Pago: ${doc['metodoPago']}\nDetalle: ${doc['nota']}'),
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

                  // Columna Totales por Día
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
                            const Text('Resumen Comercial Diario 📊', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                            const Divider(),
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: datos.obtenerTransaccionesUsuario(filtroAEscuchar),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Sin transacciones procesadas.'));

                                  final totalesPorDia = _calcularTotalesPorDia(snapshot.data!.docs);

                                  return ListView(
                                    children: totalesPorDia.entries.map((entry) {
                                      final ventasDia = entry.value['Venta'] ?? 0.0;
                                      final cobrosDia = entry.value['Cobro'] ?? 0.0;

                                      return Card(
                                        elevation: 1,
                                        margin: const EdgeInsets.symmetric(vertical: 6),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                                              const Divider(height: 10),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text("Ventas:", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                                                  Text('\$${ventasDia.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text("Cobros:", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
                                                  Text('\$${cobrosDia.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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