import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Necesario para seleccionar imágenes
import 'package:myapp/Pages/home_admin.dart';
import 'package:myapp/Services/Database.dart'; // Cambia la ruta según corresponda
import 'package:supabase/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Asegúrate de tener esto en tus dependencias

class CreateProduct extends StatelessWidget {
  const CreateProduct({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: const CreateProductScreen(),
    );
  }
}

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  _CreateProductScreenState createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _productNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  int stock = 0;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final ProductsRepository _productsRepository = ProductsRepository(Supabase.instance.client);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Producto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: (){
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ListProductsAdminScreen()));
          },
        ),
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildInputField(_productNameController, 'Nombre de Producto'),
                  const SizedBox(height: 20),
                  buildInputField(_priceController, 'Precio'),
                  const SizedBox(height: 20),
                  buildInputField(_descriptionController, 'Detalle'),
                  const SizedBox(height: 20),

                  // Stock buttons
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

                  const SizedBox(height: 20),

                  // Image upload button
                  ElevatedButton(
                    onPressed: () async {
                      final pickedFile = await _picker.pickImage(
                          source: ImageSource.gallery);
                      setState(() {
                        _imageFile = pickedFile;
                      });
                    },
                    child: const Text('Subir Imagen del Producto'),
                  ),
                  const SizedBox(height: 20),

                  // Display selected image
                  if (_imageFile != null)
                    Image.file(
                      File(_imageFile!.path),
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(height: 32),
                  buildSignInButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget buildInputField(TextEditingController controller, String label) {
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
        // Obtén los datos ingresados
        final productName = _productNameController.text;
        final price = double.tryParse(_priceController.text) ?? 0.0;
        final description = _descriptionController.text;
        final imageUrl = _imageFile != null
            ? await _uploadImage(File(_imageFile!.path))
            : 'assets/images/noimage.png';

        try {
          // Llama a la función createProduct
          await _productsRepository.createProduct(
            nombre: productName,
            precio: price,
            stock: stock,
            descripcion: description,
            imagen: imageUrl,
          );
          // Muestra un mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Producto creado exitosamente')),
          );
          // Limpia los campos
          _productNameController.clear();
          _priceController.clear();
          _descriptionController.clear();
          setState(() {
            stock = 0;
            _imageFile = null;
          });
        } catch (e) {
          // Manejo de error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al crear el producto: $e')),
          );
        }
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: Text(
          'Confirmar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
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
