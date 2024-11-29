import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/Pages/info_compra_admin.dart';

class HistorialCarritoAdmin extends StatefulWidget {
  @override
  _HistorialCarritoAdminState createState() => _HistorialCarritoAdminState();
}

class _HistorialCarritoAdminState extends State<HistorialCarritoAdmin> {
  Future<List<Map<String, dynamic>>>? _productosFuture;

  @override
  void initState() {
    super.initState();
    _productosFuture = _fetchProductos();
  }

  Future<List<Map<String, dynamic>>> _fetchProductos() async {
    try {
      final response = await Supabase.instance.client
          .from('compra_productos')
          .select('producto_id, productos(id, nombre, precio, imagen), compra(idcompra, fechacompra)')
          .order('producto_id', ascending: true);

      if (response == null) {
        throw Exception('No se recibieron datos de Supabase');
      }

      final List<Map<String, dynamic>> productos = List<Map<String, dynamic>>.from(response);

      // Agrupar productos por ID para evitar duplicados
      final Map<int, Map<String, dynamic>> productosMap = {};
      for (var producto in productos) {
        final productoId = producto['producto_id'];
        if (!productosMap.containsKey(productoId)) {
          productosMap[productoId] = producto;
        }
      }

      return productosMap.values.toList();
    } catch (e) {
      print('Error fetching products: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial Carrito Admin'),
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
              future: _productosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No hay productos disponibles.', style: TextStyle(color: Colors.white)));
                }

                final productos = snapshot.data!;

                return ListView.builder(
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final producto = productos[index]['productos'];
                    final compra = productos[index]['compra'];

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Image.network(
                          producto['imagen'],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                        title: Text(producto['nombre'], style: TextStyle(color: Colors.white)),
                        subtitle: Text('Precio: \$${producto['precio']}', style: TextStyle(color: Colors.white70)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetalleCompra(
                                productoId: producto['id'],
                              ),
                            ),
                          );
                        },
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