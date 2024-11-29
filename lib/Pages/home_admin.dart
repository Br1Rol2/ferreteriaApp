import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Services/Database.dart';
import 'package:myapp/Pages/especificacion_producto_user.dart'; // Asegúrate de importar la pantalla de detalles del producto
import 'package:myapp/Pages/log_in.dart';
import 'package:myapp/Pages/carrito_user.dart';
import 'package:myapp/Pages/create_product.dart'; // Pantalla para crear un nuevo producto // Pantalla del historial de carritos
import 'package:myapp/Pages/edit_product.dart'; // Pantalla para editar producto
import 'package:myapp/Pages/especificacion_producto_admin.dart';
import 'package:myapp/Pages/historial_carrito_admin.dart';

class ListProductsAdminScreen extends StatefulWidget {
  @override
  _ListProductsAdminScreenState createState() => _ListProductsAdminScreenState();
}

class _ListProductsAdminScreenState extends State<ListProductsAdminScreen> {
  late ProductsRepository _productsRepository;
  late Future<List<Product>> _productsFuture;
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String nickname = '';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _productsRepository = ProductsRepository(client);
    _productsFuture = _productsRepository.getAllProducts();

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.userMetadata != null) {
      nickname = user.userMetadata?['username'] ?? 'Administrador';
    } else {
      nickname = 'Administrador';
    }

    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final searchQuery = _searchController.text.toLowerCase();
    setState(() {
      if (searchQuery.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts.where((product) {
          return product.name.toLowerCase().contains(searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ferretería Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => HistorialCarritoAdmin()),
              );
            },
            tooltip: 'Historial de Carritos',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateProduct()),
              );
            },
            tooltip: 'Crear Producto',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthSignIn()),
              );
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Fondo de imagen con padding y gradiente
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 37, 37, 37).withOpacity(0.7),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // Contenido de la pantalla
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, $nickname',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Administra los productos:',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar producto...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search, color: Colors.white),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.2),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: FutureBuilder<List<Product>>(
                  future: _productsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                          child: Text('No hay productos disponibles.'));
                    } else {
                      _allProducts = snapshot.data!;

                      if (_filteredProducts.isEmpty &&
                          _searchController.text.isEmpty) {
                        _filteredProducts = _allProducts;
                      }

                      if (_filteredProducts.isEmpty &&
                          _searchController.text.isNotEmpty) {
                        return Center(
                            child: Text(
                              'No hay productos que coincidan con "${_searchController
                                  .text}".',
                            ));
                      }

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                          childAspectRatio: 0.75,
                        ),
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AdminProductDetailScreen(product: product),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          FittedBox(
                                            fit: BoxFit.contain,
                                            child: product.imageUrl != null &&
                                                product.imageUrl!.isNotEmpty
                                                ? Image.network(
                                              product.imageUrl!,
                                              width: 100,
                                              height: 100,
                                              errorBuilder: (context, error,
                                                  stackTrace) {
                                                print(
                                                    'Error loading image from URL: $error');
                                                return Image.asset(
                                                  'assets/images/noimage.png',
                                                  width: 100,
                                                  height: 100,
                                                );
                                              },
                                            )
                                                : Image.asset(
                                              'assets/images/noimage.png',
                                              width: 100,
                                              height: 100,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '\$${product.price.toStringAsFixed(2)}',
                                          style: TextStyle(
                                              color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Botones de edición y eliminación para admin
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditProductScreen(product: product),
                                            ),
                                          );
                                        },
                                        tooltip: 'Editar producto',
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () async {
                                          // Mostrar diálogo de confirmación
                                          bool? confirmDelete = await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text('Confirmar eliminación'),
                                                content: Text(
                                                    '¿Estás seguro de que deseas eliminar este producto?'),
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

                                          if (confirmDelete == true) {
                                            // Intentar eliminar el producto
                                            try {
                                              await _productsRepository
                                                  .deleteProduct(product.id);
                                              setState(() {
                                                _filteredProducts.removeAt(index);
                                              });
                                              // Mostrar Snackbar de éxito
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Producto eliminado exitosamente'),
                                                  duration: Duration(seconds: 2),
                                                ),
                                              );
                                            } catch (e) {
                                              print(
                                                  'Error al eliminar el producto: $e');
                                            }
                                          }
                                        },
                                        tooltip: 'Eliminar producto',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
