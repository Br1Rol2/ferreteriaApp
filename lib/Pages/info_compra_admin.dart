import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetalleCompra extends StatefulWidget {
  final int productoId;

  const DetalleCompra({Key? key, required this.productoId}) : super(key: key);

  @override
  _DetalleCompraState createState() => _DetalleCompraState();
}

class _DetalleCompraState extends State<DetalleCompra> {
  Future<List<Map<String, dynamic>>>? _detalleCompraFuture;

  @override
  void initState() {
    super.initState();
    _detalleCompraFuture = _fetchDetalleCompra();
  }

  Future<List<Map<String, dynamic>>> _fetchDetalleCompra() async {
    try {
      final response = await Supabase.instance.client
          .from('compra_productos')
          .select('''
            quantity,
            compra (
              idcompra,
              fechacompra,
              cliente (
                correo,
                usuario (username)
              )
            )
          ''')
          .eq('producto_id', widget.productoId);

      if (response == null) {
        throw Exception('No se recibieron datos de Supabase');
      }

      final List<Map<String, dynamic>> detalles = List<Map<String, dynamic>>.from(response);
      return detalles;
    } catch (e) {
      print('Error fetching purchase details: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de Compras'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Fondo de imagen
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Contenedor con opacidad para el contenido
          Container(
            color: Colors.black.withOpacity(0.5),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _detalleCompraFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No se encontraron detalles.', style: TextStyle(color: Colors.white)));
                }

                final detalles = snapshot.data!;

                return ListView.builder(
                  itemCount: detalles.length,
                  itemBuilder: (context, index) {
                    final detalle = detalles[index];
                    final compra = detalle['compra'];
                    final cliente = compra['cliente'];
                    final usuario = cliente['usuario'];

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: Text(usuario['username'], style: TextStyle(color: Colors.white)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cantidad: ${detalle['quantity']}', style: TextStyle(color: Colors.white70)),
                            Text('Fecha de compra: ${compra['fechacompra']}', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}