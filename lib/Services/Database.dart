import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductsRepository {
  final SupabaseClient _client;

  ProductsRepository(this._client);

  //////////////////////////////////////Home - allproducts//////////////////////
  Future<List<Product>> getAllProducts() async {
    final response = await _client
        .from('productos') // Nombre de tu tabla de productos
        .select();

    // Asegúrate de que response.data sea del tipo List
    if (response is List) {
      List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
          response as List);
      return data.map((map) => Product.fromMap(map)).toList();
    } else {
      throw Exception('Datos no válidos recibidos de la base de datos');
    }
  }

  //////////////////////////////////////Carrito/////////////////////////////////
  Future<List<CartItem>> getCartItems(int clienteId) async {
    final response = await _client
        .from('carrito_productos')
        .select(
        'producto_id, quantity, productos(nombre, precio, imagen, descripcion,stock)')
        .eq('cliente_id',
        clienteId); // Asegúrate de que estás llamando a 'execute()'

    final data = response as List<dynamic>?;

    // Si no hay datos, también lanzamos una excepción
    if (data == null || data.isEmpty) {
      throw Exception('No se encontraron productos en el carrito');
    }
    return data.map((item) {
      final producto = Product(
          id: item['producto_id'],
          name: item['productos']['nombre'],
          price: (item['productos']['precio'] as num).toDouble(),  // Convertir a double si es necesario
          imageUrl: item['productos']['imagen'],
          description: item['productos']['descripcion'],
          // Corregido 'proudctos' a 'productos'
          stock: item['productos']['stock']
      );
      return CartItem(product: producto, quantity: item['quantity'] ?? 1);
    }).toList();
  }

//****************************************************************************************************************//
  Future<void> updateStock(int clienteId, int productId, int quantity) async {
    final response = await _client
        .from('carrito_productos')
        .update({'quantity': quantity})
        .match({'cliente_id': clienteId, 'producto_id': productId});

    if (response != null) {
      throw Exception(
          'Error al actualizar el stock: ${response.error!.message}');
    }
  }

//****************************************************************************************************************//
  Future<void> removeItem(int clienteId, int productId) async {
    try {
      // Eliminar el producto del carrito
      await _client
          .from('carrito_productos')
          .delete()
          .match({'cliente_id': clienteId, 'producto_id': productId});
    } catch (e) {
      throw Exception('Error al eliminar el producto del carrito: $e');
    }
  }

//****************************************************************************************************************//
  Future<void> clearCart(int clienteId) async {
    final response = await _client
        .from('carrito_productos')
        .delete()
        .eq('cliente_id', clienteId);

    if (response != null) {
      throw Exception(
          'Error al limpiar el carrito: ${response.error!.message}');
    }
  }

//****************************************************************************************************************//
  Future<void> completePurchase(int clienteId) async {
    // 1. Insertar un nuevo registro en la tabla `compra`
    final compraResponse = await _client.from('compra').insert({
      'fechacompra': DateTime.now().toIso8601String(),
      // Fecha de compra
      'costocarrito': await _calculateCartTotal(clienteId),
      // Costo total del carrito
      'idcliente': clienteId,
    }).select('idcompra').single();


    // Obtener el ID de la compra recién creada
    final compraId = compraResponse['idcompra'] as int;

    // 2. Insertar los productos del carrito en la tabla `compra_productos`
    final carritoResponse = await _client
        .from('carrito_productos')
        .select('producto_id, quantity')
        .eq('cliente_id', clienteId);


    final productos = carritoResponse as List<dynamic>;

    final insertProductosResponse = await _client
        .from('compra_productos')
        .insert(productos.map((producto) {
      return {
        'compra_id': compraId,
        'producto_id': producto['producto_id'],
        'quantity': producto['quantity'],
      };
    }).toList());


    // 3. Eliminar los productos del carrito
    final deleteResponse = await _client
        .from('carrito_productos')
        .delete()
        .eq('cliente_id', clienteId);
  }

//****************************************************************************************************************//
  Future<double> _calculateCartTotal(int clienteId) async {
    final response = await _client
        .from('carrito_productos')
        .select('quantity, producto_id')
        .eq('cliente_id', clienteId);


    final productos = response as List<dynamic>;
    double total = 0.0;

    for (var producto in productos) {
      final productResponse = await _client
          .from('productos')
          .select('precio')
          .eq('id', producto['producto_id'])
          .single();

      final precio = productResponse['precio'] as double;
      final quantity = producto['quantity'] as int;
      total += precio * quantity;
    }

    return total;
  }

//****************************************************************************************************************//
  Future<void> addProductToCart(int clienteId, int productId,
      int quantity) async {
    // verifica si el producto esta en la tabla carrito
    final existingProduct = await _client
        .from('carrito_productos')
        .select()
        .eq('cliente_id', clienteId)
        .eq('producto_id', productId)
        .maybeSingle(); // Obtiene el registro si existe

    if (existingProduct != null) {
      // si esta en la tabla modifica la cantidad
      final newQuantity = existingProduct['quantity'] + quantity;

      await _client
          .from('carrito_productos')
          .update({
        'quantity': newQuantity,
      })
          .eq('cliente_id', clienteId)
          .eq('producto_id', productId);
    } else {
      // añade el producto a la tabla ya que no existe
      await _client
          .from('carrito_productos')
          .insert({
        'cliente_id': clienteId,
        'producto_id': productId,
        'quantity': quantity,
      });
    }
  }

  /////////////////////////////otra/////////////////////////////////////////////

  Future<int?> getUserIdByEmail(String email) async {
    final response = await _client
        .from('cliente') // Nombre de tu tabla
        .select('id') // Campo que quieres obtener
        .eq('correo', email) // Criterio de búsqueda
        .single(); // Espera un solo resultado

    if (response == null) {
      throw Exception(
          'Error al obtener el ID del usuario: ${response}  $email');
    }
    print('$response');
    final data = response as Map<String, dynamic>?;
    return data?['id'] as int?;
  }

//*********************************************crear producto*******************************************************************//

  Future<void> createProduct({
    required double precio,
    required int stock,
    String? descripcion,
    String? imagen,
    required String nombre,
  }) async {
    try {
      final response = await _client
          .from('productos')
          .insert({
        'precio': precio,
        'stock': stock,
        'descripcion': descripcion,
        'imagen': imagen,
        'nombre': nombre,
      });

    } catch (e) {
      print('Error al insertar el producto: $e');
    }
  }

//*********************************************eliminar producto*******************************************************************//
  Future<void> deleteProduct(int productId) async {
    try {
      final response = await _client
          .from('productos')
          .delete()
          .eq('id', productId);

      print('Producto eliminado con éxito.');
    } catch (e) {
      print('Error al eliminar el producto: $e');
    }
  }

  //*********************************************actualizar producto*******************************************************************//
  Future<void> updateProduct({
    required int id,
    required double precio,
    required int stock,
    String? descripcion,
    String? imagen,
    required String nombre,
  }) async {
    try {
      final response = await _client
          .from('productos')
          .update({
        'precio': precio,
        'stock': stock,
        'descripcion': descripcion,
        'imagen': imagen,
        'nombre': nombre,
      })
          .eq('id', id);
    } catch (e) {
      print('Error al actualizar el producto: $e');
    }
  }



//*********************************************Historial carrito user*******************************************************************//
  Future<List<Map<String, dynamic>>> fetchCompras(int clienteId) async {
    // Fetching the purchase data
    final response = await _client
        .from('compra')
        .select('idcompra, costocarrito, fechacompra, idcliente')
        .eq('idcliente', clienteId);

    // Casting response to List<Map<String, dynamic>>
    final compras = (response as List<dynamic>)
        .map((item) => item as Map<String, dynamic>)
        .toList();

    // Fetching the quantity of products for each purchase
    for (var compra in compras) {
      final compraId = compra['idcompra'];
      final productosResponse = await _client
          .from('compra_productos')
          .select('quantity')
          .eq('compra_id', compraId);

      final cantidadProductos = (productosResponse as List<dynamic>).length;

      compra['cantidad_productos'] = cantidadProductos;
    }

    return compras;
  }


  Future<void> deleteAllCompras(int clienteId) async {
    try {
      // Obtener todas las compras del cliente
      final comprasResponse = await _client
          .from('compra')
          .select('idcompra')
          .eq('idcliente', clienteId);


      final compras = comprasResponse as List<dynamic>;

      // Verificar que hay compras para eliminar
      if (compras.isNotEmpty) {
        // Obtener todos los idcompra
        final compraIds = compras.map((compra) => compra['idcompra'] as int).toList();

        // Eliminar todas las entradas en compra_productos para cada idcompra
        for (final idcompra in compraIds) {
          final deleteCompraProductoResponse = await _client
              .from('compra_productos')
              .delete()
              .eq('compra_id', idcompra);


        }

        // Ahora eliminar todas las compras del cliente
        final deleteCompraResponse = await _client
            .from('compra')
            .delete()
            .eq('idcliente', clienteId);


      }
    } catch (e) {
      throw Exception('Error al eliminar todas las compras: $e');
    }
  }






}



class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, required this.quantity});
}

class Product {
  final int id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;
  final int stock; // Añadido el campo stock

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.stock, // Añadido el campo stock en el constructor
  });

  factory Product.fromMap(Map<String, dynamic> data) {
    return Product(
      id: data['id'] ?? 0,
      name: data['nombre'] ?? '',
      price: (data['precio'] is num ? (data['precio'] as num).toDouble() : 0.0),
      imageUrl: data['imagen'] ?? '',
      description: data['descripcion'] ?? '',
      stock: data['stock'] ?? 0 // Añadido el campo stock
    );
  }
}
//////////////////////////////////////////////////
