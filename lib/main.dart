import 'package:flutter/material.dart';

void main() {
  runApp(const OmniWalletApp());
}

class OmniWalletApp extends StatelessWidget {
  const OmniWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Omni Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      // Definimos que o App começa na tela de Login
      home: const LoginView(),
    );
  }
}

// --- TELA DE LOGIN ---
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Imagem de Fundo (Nome atualizado para "tela_fundo_OW.png")
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/tela_fundo_OW.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.55)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  children: [
                    const Text("OMNI WALLET", style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: 3)),
                    const SizedBox(height: 50),
                    _buildTextField(hint: "E-mail", icon: Icons.email),
                    const SizedBox(height: 15),
                    _buildTextField(hint: "Senha", icon: Icons.lock, isPassword: true),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {},
                      style: _buttonStyle(),
                      child: const Text("ENTRAR"),
                    ),
                    const SizedBox(height: 20),
                    // BOTÃO QUE LEVA PARA O CADASTRO
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterView()),
                        );
                      },
                      child: const Text("Ainda não tem conta? Cadastre-se", style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- TELA DE CADASTRO ---
class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Botão de voltar automático no AppBar transparente
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: Stack(
        children: [
          // 1. Imagem de Fundo (Nome atualizado para "tela_fundo_OW.png")
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/tela_fundo_OW.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.55)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  children: [
                    const Text("CRIAR CONTA", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 10),
                    const Text("Preencha os dados abaixo", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 40),
                    _buildTextField(hint: "Nome Completo", icon: Icons.person),
                    const SizedBox(height: 15),
                    _buildTextField(hint: "E-mail", icon: Icons.email),
                    const SizedBox(height: 15),
                    _buildTextField(hint: "Crie uma Senha", icon: Icons.lock, isPassword: true),
                    const SizedBox(height: 15),
                    _buildTextField(hint: "Confirme a Senha", icon: Icons.lock_outline, isPassword: true),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Volta para o login
                      },
                      style: _buttonStyle(),
                      child: const Text("FINALIZAR CADASTRO"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- COMPONENTES REUTILIZÁVEIS ---

Widget _buildTextField({required String hint, required IconData icon, bool isPassword = false}) {
  return TextField(
    obscureText: isPassword,
    style: const TextStyle(color: Colors.black87),
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      prefixIcon: Icon(icon, color: Colors.teal),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
  );
}

ButtonStyle _buttonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: Colors.teal[700],
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 55),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 5,
  );
}