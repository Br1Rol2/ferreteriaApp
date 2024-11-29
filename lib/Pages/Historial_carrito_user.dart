import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/Services/Database.dart';
import 'package:myapp/Pages/info_compra_user.dart';


class HistorialCompraUser extends StatefulWidget {
  @override
  _HistorialCompraUserState createState() => _HistorialCompraUserState();
}

class _HistorialCompraUserState extends State<HistorialCompraUser> {
  late ProductsRepository _productsRepository;
  late Future<List<Map<String, dynamic>>> _comprasFuture = Future.value([]);

  @override
  void initState() {
    super.initState();
    _productsRepository = ProductsRepository(Supabase.instance.client);
    _fetchClienteIdAndCompras();
  }

  Future<void> _fetchClienteIdAndCompras() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user != null && user.userMetadata != null) {
        final userEmail = user.userMetadata?['email'];
        if (userEmail != null) {
          // Obtener el ID del cliente a partir del email del usuario
          final clienteId = await _productsRepository.getUserIdByEmail(
              userEmail);

          // Asegurarse de que clienteId no sea nulo
          if (clienteId != null) {
            setState(() {
              // Cargar las compras después de obtener el clienteId
              _comprasFuture = _productsRepository.fetchCompras(clienteId);
            });
          } else {
            // Manejo del caso en el que clienteId es nulo
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ID del cliente no encontrado.')),
            );
          }
        }
      }
    } catch (e) {
      // Manejo de errores
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener el cliente ID: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial Carrito'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              // Mostrar diálogo de confirmación
              bool? confirmDelete = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Confirmar eliminación'),
                    content: Text('¿Estás seguro de que deseas eliminar el historial?'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Cancelar'),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                      TextButton(
                        child: Text('Eliminar'),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ],
                  );
                },
              );

              // Si el usuario confirma la eliminación, proceder con la acción
              if (confirmDelete == true) {
                try {
                  // Llama al método de eliminación
                  await _deleteAllCompras();

                  // Muestra un mensaje de éxito
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Historial eliminado exitosamente'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  // Manejo de errores
                  print('Error al eliminar el historial: $e');
                }
              }
            },
            tooltip: 'Eliminar producto',
          ),

        ],
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
              color: Colors.black.withOpacity(0.5), // Ajusta la opacidad según sea necesario
            ),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _comprasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No hay compras disponibles.'));
                }

                final compras = snapshot.data!;

                return ListView.builder(
                  itemCount: compras.length,
                  itemBuilder: (context, index) {
                    final compra = compras[index];
                    return ListTile(
                      contentPadding: EdgeInsets.all(8.0),
                      // Utiliza un Row para colocar la imagen a la izquierda y el texto a la derecha
                      leading: Card(
                        margin: EdgeInsets.zero, // Elimina márgenes adicionales
                        elevation: 4,
                        child: Image.asset(
                          'assets/images/carrito.png', // Cambia esto por el nombre y la ruta de tu imagen
                          width: 40, // Ajusta el tamaño según sea necesario
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text('ID Compra: ${compra['idcompra']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fecha: ${compra['fechacompra']}'),
                          Text('Costo Total: ${compra['costocarrito'].toStringAsFixed(2)}'),
                          Text('Cantidad de Productos: ${compra['cantidad_productos']}'),
                        ],
                      ),
                      onTap: () {
                        // Navegar a la vista de productos de la compra
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubHistorialUser(idCompra: compra['idcompra']),
                          ),
                        );
                      },
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


  Future<void> _deleteAllCompras() async {
    try {
      // Obtén el clienteId de nuevo aquí si es necesario
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null && user.userMetadata != null) {
        final userEmail = user.userMetadata?['email'];
        if (userEmail != null) {
          final clienteId = await _productsRepository.getUserIdByEmail(
              userEmail);
          if (clienteId != null) {
            await _productsRepository.deleteAllCompras(clienteId);
            setState(() {
              // Recargar las compras después de eliminar
              _fetchClienteIdAndCompras();
            });
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar compras: $e')),
      );
    }
  }
}
