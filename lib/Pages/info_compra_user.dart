import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubHistorialUser extends StatefulWidget {
  final int idCompra;

  const SubHistorialUser({Key? key, required this.idCompra}) : super(key: key);

  @override
  _SubHistorialUserState createState() => _SubHistorialUserState();
}

class _SubHistorialUserState extends State<SubHistorialUser> {
  Future<Map<String, dynamic>>? _compraFuture;

  @override
  void initState() {
    super.initState();
    _compraFuture = _fetchCompraDetalles(widget.idCompra);
  }

  Future<Map<String, dynamic>> _fetchCompraDetalles(int idCompra) async {
    final response = await Supabase.instance.client
        .from('compra')
        .select('idcompra, fechacompra, costocarrito, compra_productos(producto_id, quantity, productos(nombre, precio, imagen))')
        .eq('idcompra', idCompra)
        .single(); // Para obtener un solo resultado


    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de Compra'),
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
                image: AssetImage('assets/images/background.png'), // Ajusta la ruta a tu imagen
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Contenedor con opacidad para el contenido
          Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
            ),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _compraFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  return Center(child: Text('No se encontraron detalles de la compra.'));
                }

                final compra = snapshot.data!;
                final productos = compra['compra_productos'] as List<dynamic>;

                return Column(
                  children: [
                    // Lista de productos
                    Expanded(
                      child: ListView.builder(
                        itemCount: productos.length,
                        itemBuilder: (context, index) {
                          final producto = productos[index]['productos'];
                          final cantidad = productos[index]['quantity'];

                          return ListTile(
                            leading: Image.network(
                              producto['imagen'],
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                            title: Text(producto['nombre']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Precio: \$${producto['precio']}'),
                                Text('Cantidad: $cantidad'),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // Mostrar la fecha de la compra y el costo total
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fecha de compra: ${compra['fechacompra']}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Costo total: \$${compra['costocarrito'].toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
