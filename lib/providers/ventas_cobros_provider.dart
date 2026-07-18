import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VentasCobrosProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> obtenerCategorias() {
    return _firestore.collection('categorias').snapshots();
  }

  Stream<QuerySnapshot> obtenerMetodosPago() {
    return _firestore.collection('metodos_pago').snapshots();
  }

  Future<void> guardarTransaccion({
    required String uidUsuario,
    required String emailUsuario,
    required double monto,
    required String category,
    required String metodoPago,
    required String nota,
    required String tipo,
  }) async {
    await _firestore.collection('ventas_cobros').add({
      'uidUsuario': uidUsuario,
      'emailUsuario': emailUsuario,
      'monto': monto,
      'categoria': category,
      'metodoPago': metodoPago,
      'nota': nota,
      'tipo': tipo,
      'fecha': DateTime.now(),
    });
  }

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

  Stream<List<String>> obtenerTodosLosUsuariosComerciales() {
    return _firestore.collection('ventas_cobros').snapshots().map((snapshot) {
      final correos = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return data.containsKey('emailUsuario')
                ? doc['emailUsuario'].toString()
                : doc['uidUsuario'].toString();
          })
          .toSet()
          .toList();
      return correos;
    });
  }
}
