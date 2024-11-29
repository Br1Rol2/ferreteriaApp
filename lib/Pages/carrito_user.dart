import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Services/Database.dart';
import 'package:myapp/Pages/home.dart'; // Asegúrate de importar la pantalla de inicio

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late ProductsRepository _productsRepository;
  List<CartItem> _cartItems = [];
  int _totalProducts = 0;
  double _totalPrice = 0.0;



//  final user = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _productsRepository = ProductsRepository(Supabase.instance.client);

    _loadCartItems();
  }

  void _loadCartItems() async {
    final user = Supabase.instance.client.auth.currentUser;
    try {
      if (user != null && user.userMetadata != null) {
        final userEmail = user.userMetadata?['email'];
        print('$userEmail');
        if (userEmail != null) {
          // Obtener el ID del cliente a partir del email del usuario
          final clienteId = await _productsRepository.getUserIdByEmail(userEmail);

          if (clienteId != null) {
            // Obtener los productos del carrito basados en el ID del cliente
            final cartItems = await _productsRepository.getCartItems(clienteId);
            setState(() {
              _cartItems = cartItems;
              _updateTotals();
            });
          } else {
            // Manejo de error si el clienteId es null
            print('ID de cliente no disponible');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ID de cliente no disponible')),
            );
          }
        }
      } else {
        // Manejo de error si el usuario no está autenticado o no tiene metadata
        print('Usuario no autenticado o sin metadata');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Usuario no autenticado')),
        );
      }
    } catch (e) {
      // Manejo de error en caso de fallo al obtener los productos del carrito
      print('Error al cargar los productos del carrito: $e');
      //ScaffoldMessenger.of(context).showSnackBar(
        //SnackBar(content: Text('Error al cargar los productos del carrito')),
      //);
    }
  }

  void _updateTotals() {
    _totalProducts = _cartItems.fold(0, (sum, item) => sum + item.quantity);
    _totalPrice = _cartItems.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  void _increaseStock(CartItem item) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null || user.userMetadata == null) {
      print('Usuario no autenticado o sin metadata');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Usuario no autenticado')),
      );
      return;
    }

    final userEmail = user.userMetadata?['email'];
    if (userEmail == null) {
      print('Correo electrónico del usuario no disponible');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Correo electrónico del usuario no disponible')),
      );
      return;
    }

    try {
      // Obtener el ID del cliente a partir del correo electrónico
      final clienteId = await _productsRepository.getUserIdByEmail(userEmail);

      if (clienteId != null) {
        // Aumentar la cantidad
        item.quantity++;
        await _productsRepository.updateStock(clienteId, item.product.id, item.quantity);
        setState(() {
          _updateTotals();
        });
      } else {
        throw Exception('No se encontró el ID del cliente.');
      }
    } catch (e) {
      // Maneja el error aquí
      print('Error al aumentar el stock: $e');
    }
  }

  void _decreaseStock(CartItem item) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null || user.userMetadata == null) {
      print('Usuario no autenticado o sin metadata');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Usuario no autenticado')),
      );
      return;
    }

    final userEmail = user.userMetadata?['email'];
    if (userEmail == null) {
      print('Correo electrónico del usuario no disponible');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Correo electrónico del usuario no disponible')),
      );
      return;
    }

    try {
      // Obtener el ID del cliente a partir del correo electrónico
      final clienteId = await _productsRepository.getUserIdByEmail(userEmail);

      if (clienteId != null && item.quantity > 1) {
        // Disminuir la cantidad
        item.quantity--;
        await _productsRepository.updateStock(clienteId, item.product.id, item.quantity);
        setState(() {
          _updateTotals();
        });
      } else {
        throw Exception('No se encontró el ID del cliente o la cantidad es inválida.');
      }
    } catch (e) {
      // Maneja el error aquí
      print('Error al disminuir el stock: $e');
    }
  }
//********************************************************************************************//
  void _removeItem(CartItem item) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null || user.userMetadata == null) {
      print('Usuario no autenticado o sin metadata');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Usuario no autenticado')),
      );
      return;
    }

    final userEmail = user.userMetadata?['email'];
    if (userEmail == null) {
      print('Correo electrónico del usuario no disponible');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Correo electrónico del usuario no disponible')),
      );
      return;
    }

    try {
      // Obtén el clienteId usando el correo electrónico del cliente
      final clienteId = await _productsRepository.getUserIdByEmail(userEmail);
      if (clienteId != null) {
        // Elimina el producto del carrito usando el clienteId
        await _productsRepository.removeItem(clienteId, item.product.id);

        setState(() {
          _cartItems.remove(item);
          _updateTotals();
        });
      } else {
        throw Exception('No se encontró el ID del cliente.');
      }
    } catch (e) {
      print('Error al eliminar el producto del carrito: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el producto del carrito')),
      );
    }
  }


//********************************************************************************************//


  void _clearCart() async {
    try {
      await _productsRepository.clearCart(1);
      setState(() {
        _cartItems.clear();
        _updateTotals();
      });
    } catch (e) {
      // Maneja el error aquí
      print('Error al limpiar el carrito: $e');
    }
  }

  void _completePurchase() async {
    try {
      // Obtener el usuario autenticado de Supabase
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null && user.userMetadata != null) {
        final userEmail = user.userMetadata?['email'];
        print('Email del usuario: $userEmail');

        if (userEmail != null) {
          // Obtener el ID del cliente usando el correo electrónico
          final clienteId = await _productsRepository.getUserIdByEmail(userEmail);

          if (clienteId != null) {
            // Llamar a la función de completar compra con el ID del cliente verdadero
            await _productsRepository.completePurchase(clienteId);

            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Compra realizada'),
                content: Text('La compra se ha realizado correctamente.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => ListProductsScreen()),
                      );
                    },
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            throw Exception('No se encontró el cliente con el correo proporcionado.');
          }
        }
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('No se pudo completar la compra: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carrito Ferretería'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _clearCart,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Imagen de fondo
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png', // Ruta de la imagen de fondo
              fit: BoxFit.cover, // Ajusta la imagen cubriendo todo el espacio disponible
            ),
          ),
          // Contenido encima de la imagen de fondo
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6), // Fondo oscuro con opacidad
              borderRadius: BorderRadius.circular(8), // Esquinas redondeadas opcionales
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      ..._cartItems.map((item) => ListTile(
                        leading: Container(
                          width: 50, // Ajusta el tamaño si es necesario
                          height: 50, // Ajusta el tamaño si es necesario
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6), // Fondo oscuro para la imagen
                            borderRadius: BorderRadius.circular(8), // Esquinas redondeadas opcionales
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0), // Espacio alrededor de la imagen
                            child: Image.network(
                              item.product.imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(
                          item.product.name,
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${item.product.price} x ${item.quantity}',
                          style: TextStyle(color: Colors.white),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, color: Colors.white),
                              onPressed: () => _decreaseStock(item),
                            ),
                            Text(
                              '${item.quantity}',
                              style: TextStyle(color: Colors.white),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, color: Colors.white),
                              onPressed: () => _increaseStock(item),
                            ),
                            IconButton(

                              icon: Icon(Icons.delete, color: Colors.white),
                              onPressed: () => _removeItem(item,),
                            ),

                          ],
                        ),
                      )),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Total de productos: $_totalProducts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  'Precio total: \$${_totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, // Color de fondo del botón
                  ),
                  onPressed: _completePurchase,
                  child: Text(
                      'Realizar compra',
                  style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}
