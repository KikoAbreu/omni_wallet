import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 1. Importa o pacote

void main() async {
  // 2. Garante que os componentes do Flutter estejam prontos antes de rodar código assíncrono
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Liga o motor do Supabase na inicialização do App
  await Supabase.initialize(
    url: 'https://lvojfkgbrzeymuafuvts.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx2b2pma2dicnpleW11YWZ1dnRzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1ODMwMzcsImV4cCI6MjA5NDE1OTAzN30.1oPd8XTYn6CEpD7DBny6rqUYLJIJSN-hpzs0SPy-atM',
  );

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

// --- TELA DE CADASTRO (AGORA STATEFUL E CONECTADA AO BANCO) ---
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  // Controladores para capturar o texto dos inputs
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmaSenhaController = TextEditingController();

  bool _carregando = false; // Estado para mostrar um indicador de loading no botão

  // Função que faz o cadastro no Supabase
  Future<void> _cadastrarUsuario() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();
    final confirmaSenha = _confirmaSenhaController.text.trim();

    // Validações básicas (Melhoria de Usabilidade e Segurança)
    if (nome.isEmpty || email.isEmpty || senha.isEmpty || confirmaSenha.isEmpty) {
      _mostrarMensagem("Por favor, preencha todos os campos!");
      return;
    }

    if (senha != confirmaSenha) {
      _mostrarMensagem("As senhas não coincidem!");
      return;
    }

    setState(() {
      _carregando = true; // Ativa o círculo de carregamento
    });

    try {
      // Envia os dados para a tabela do Supabase que você acabou de criar
      await Supabase.instance.client.from('usuarios').insert({
        'nome': nome,
        'email': email,
        'senha': senha, // Em produção usaríamos hash, para a AV2 a string limpa resolve perfeitamente
      });

      _mostrarMensagem("Cadastro realizado com sucesso!", sucesso: true);

      // Retorna para a tela de login após 1.5 segundos
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.pop(context);

    } catch (erro) {
      _mostrarMensagem("Erro ao cadastrar: ${erro.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false; // Desativa o carregamento
        });
      }
    }
  }

  // Helper para mostrar notificações na tela (SnackBar)
  void _mostrarMensagem(String mensagem, {bool sucesso = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: sucesso ? Colors.green[700] : Colors.red[800],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    // Limpa os controladores da memória ao sair da tela
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmaSenhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: Stack(
        children: [
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

                    // Vinculamos cada campo ao seu respectivo controller
                    _buildTextField(hint: "Nome Completo", icon: Icons.person, controller: _nomeController),
                    const SizedBox(height: 15),
                    _buildTextField(hint: "E-mail", icon: Icons.email, controller: _emailController),
                    const SizedBox(height: 15),
                    _buildTextField(hint: "Crie uma Senha", icon: Icons.lock, isPassword: true, controller: _senhaController),
                    const SizedBox(height: 15),
                    _buildTextField(hint: "Confirme a Senha", icon: Icons.lock_outline, isPassword: true, controller: _confirmaSenhaController),
                    const SizedBox(height: 30),

                    ElevatedButton(
                      onPressed: _carregando ? null : _cadastrarUsuario, // Desabilita o clique múltiplo se estiver carregando
                      style: _buttonStyle(),
                      child: _carregando
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("FINALIZAR CADASTRO"),
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

Widget _buildTextField({required String hint, required IconData icon, bool isPassword = false, TextEditingController? controller}) {
  return TextField(
    controller: controller, // Recebe o controlador
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