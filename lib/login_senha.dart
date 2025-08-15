import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart'; // Importa a nova tela principal

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Instância do Firebase Authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Função para mostrar mensagens de erro ou sucesso
  void _mostrarFeedback(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // --- FUNÇÃO DE LOGIN COM FIREBASE ---
  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _mostrarFeedback('Por favor, preencha e-mail e senha.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Navega para a HomePage se o login for bem-sucedido
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _mostrarFeedback(e.message ?? 'Ocorreu um erro.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- FUNÇÃO DE REGISTRO COM FIREBASE ---
  Future<void> _register() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _mostrarFeedback('Por favor, preencha e-mail e senha para registrar.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      _mostrarFeedback('Usuário registrado com sucesso! Por favor, faça o login.');
    } on FirebaseAuthException catch (e) {
      _mostrarFeedback(e.message ?? 'Ocorreu um erro no registro.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Glamour Studio',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 40),
              ),
              const SizedBox(height: 8),
              Text(
                'Bem-vindo(a) de volta!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFE0E1DD)
                ),
              ),
              const SizedBox(height: 50),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined, color: Color(0xFFE0E1DD)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFE0E1DD)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFFE0E1DD),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: Theme.of(context).hintColor))
                  : ElevatedButton(
                onPressed: _login,
                child: const Text('Entrar'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _register,
                child: Text(
                  'Não tem uma conta? Registre-se',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
