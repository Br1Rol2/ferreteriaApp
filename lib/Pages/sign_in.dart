import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/Pages/log_in.dart';

import '../main.dart';

class Sign_in extends StatefulWidget {
  const Sign_in({super.key});

  @override
  _Sign_inState createState() => _Sign_inState();
}

class _Sign_inState extends State<Sign_in> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  //Sign Up USER con supabase auth
  Future<void> signIn() async {
    try {
      // Registrar usuario con Supabase
      final response = await supabase.auth.signUp(
        password: _passwordController.text.trim(),
        email: _emailController.text.trim(),
        data: {'username': _usernameController.text.trim()},
      );

      final userId = response.user?.id;
      final email = _emailController.text.trim();
      final username = _usernameController.text.trim();

      if (userId != null) {
        // Insertar en la tabla 'usuario'
        await supabase.from('usuario').insert({
          'username': username,
          'correo': email,
          'password': _passwordController.text.trim(),
        });

        // Extraer el dominio del correo
        final emailDomain = email.split('@').last;

        // Verificar si el dominio es 'admin'
        if (emailDomain == 'admin') {
          // Insertar en la tabla 'administrador' si el dominio es 'admin'
          await supabase.from('administrador').insert({
            'correo': email,
            // Otros campos si es necesario
          });
        } else {
          // Insertar en la tabla 'cliente' si no es 'admin'
          await supabase.from('cliente').insert({
            'correo': email,
          });
        }
      }

      // Navegar a la vista 'AuthSignIn' después de logearse correctamente
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthSignIn()),
      );
    } on AuthException catch (e) {
      // Manejar error de autenticación
      print('Error during sign-up: $e');
    } catch (e) {
      // Manejar otros errores
      print('Error: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagen de fondo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'), // Ruta de la imagen
                fit: BoxFit.cover, // Ajusta la imagen al tamaño de la pantalla
              ),
            ),
          ),
          // Gradiente negro con opacidad
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color.fromARGB(255, 37, 37, 37).withOpacity(0.7), // Hacemos el gradiente más transparente
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Registrarse',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                buildInputField('Nombre de usuario', _usernameController),
                const SizedBox(height: 20),
                buildInputField('Correo electrónico', _emailController),
                const SizedBox(height: 20),
                buildInputField('Contraseña', _passwordController, isPassword: true),
                const SizedBox(height: 32),
                buildSignInButton(),
                const SizedBox(height: 24),
                buildSignUpText(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInputField(String hintText, TextEditingController controller, {bool isPassword = false}) {
    return Container(
      width: double.infinity,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFBABABA)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !_isPasswordVisible : false,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFBABABA)),
          icon: Icon(
            isPassword ? Icons.lock : Icons.person,
            color: const Color(0xFFBABABA),
          ),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: const Color(0xFFBABABA),
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          )
              : null,
        ),
      ),
    );
  }

  Widget buildSignInButton() {
    return GestureDetector(
      onTap: signIn,
      child: Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF0ACF83),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Text(
          'Registrar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      ),
    );
  }

  Widget buildSignUpText(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(
            text: 'Ya tienes cuenta? ',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          TextSpan(
            text: 'Inicia sesión aquí',
            style: const TextStyle(
              color: Color(0xFF0ACF83),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.pop(context);
              },
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
