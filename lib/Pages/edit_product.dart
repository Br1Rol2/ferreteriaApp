import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../Services/Database.dart';
import 'package:myapp/Pages/home_admin.dart';
import 'package:supabase/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProduct extends StatelessWidget {
  final Product product;

  const EditProduct({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: EditProductScreen(product: product),
    );
  }
}

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _idController;
  int stock = 0;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _descriptionController = TextEditingController(text: widget.product.description);
    _idController = TextEditingController(text: widget.product.id.toString());
    stock = widget.product.stock;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Producto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ListProductsAdminScreen()),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color.fromARGB(255, 37, 37, 37).withOpacity(0.7),
                    Colors.black.withOpacity(0.0),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  buildInputField('Nombre del producto', _nameController),
                  const SizedBox(height: 20),
                  buildInputField('Precio', _priceController),
                  const SizedBox(height: 20),
                  buildInputField('Descripción', _descriptionController),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            if (stock > 0) stock--;
                          });
                        },
                      ),
                      Text(
                        'Stock: $stock',
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            stock++;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (_imageFile != null)
                    Image.file(
                      File(_imageFile!.path),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                  else
                    Image.network(
                      widget.product.imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () async {
                      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                      setState(() {
                        _imageFile = pickedFile;
                      });
                    },
                    child: const Text('Actualizar Imagen del Producto'),
                  ),
                  const SizedBox(height: 15),
                  buildSignInButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInputField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0ACF83)),
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget buildSignInButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0ACF83),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () async {
        final ProductsRepository _productsRepository = ProductsRepository(Supabase.instance.client);
        final id = int.parse(_idController.text);
        final productName = _nameController.text;
        final price = double.tryParse(_priceController.text) ?? 0.0;
        final description = _descriptionController.text;
        final imageUrl = _imageFile != null
            ? await _uploadImage(File(_imageFile!.path))
            : widget.product.imageUrl;

        try {
          await _productsRepository.updateProduct(
            id: id,
            nombre: productName,
            precio: price,
            stock: stock,
            descripcion: description,
            imagen: imageUrl,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto actualizado exitosamente')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar el producto: $e')),
          );
        }
      },
      child: const Center(
        child: Text(
          'Guardar cambios',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.uri.pathSegments.last}';
      // Subir la imagen al bucket de Supabase
      final response = await Supabase.instance.client
          .storage
          .from('product_images') // Cambia el nombre del bucket si es diferente
          .upload(
        fileName, // Ruta del archivo
        imageFile,
        fileOptions: const FileOptions(
          cacheControl: '3600', // Control de caché opcional
          upsert: false, // Para evitar sobrescribir archivos existentes
        ),
      );

      // Obtener la URL pública de la imagen subida
      final imageUrl = Supabase.instance.client.storage
          .from('product_images') // Asegúrate de usar el nombre correcto del bucket
          .getPublicUrl(fileName);
      print('Nombre: $fileName -    url: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
