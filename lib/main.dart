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
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Controladores para capturar o e-mail e a senha digitados
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _carregando = false; // Estado para o círculo de loading no botão

  // Função que valida as credenciais no Supabase
  Future<void> _fazerLogin() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    // Validação visual simples
    if (email.isEmpty || senha.isEmpty) {
      _mostrarMensagem("Por favor, preencha todos os campos!");
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      // Faz uma busca na tabela 'usuarios' procurando pelo email E pela senha digitados
      final resposta = await Supabase.instance.client
          .from('usuarios')
          .select()
          .eq('email', email)
          .eq('senha', senha)
          .maybeSingle(); // Retorna um registro ou null se não achar nada

      if (resposta == null) {
        _mostrarMensagem("E-mail ou senha incorretos!");
      } else {
        _mostrarMensagem("Login efetuado com sucesso!", sucesso: true);

        await Future.delayed(const Duration(milliseconds: 1000));

        if (mounted) {
          // Pega o nome do usuário que veio direto do banco de dados do Supabase
          String nomeUsuario = resposta['nome'] ?? 'Usuário';

          // Navega para a Home fechando a tela de Login para o usuário não voltar nela ao clicar em "Voltar"
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeView(userName: nomeUsuario),
            ),
          );
        }
      }

    } catch (erro) {
      _mostrarMensagem("Erro ao conectar: ${erro.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

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
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

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

                    // Vinculando os controladores aos inputs criados
                    _buildTextField(hint: "E-mail", icon: Icons.email, controller: _emailController),
                    const SizedBox(height: 15),
                    _buildTextField(hint: "Senha", icon: Icons.lock, isPassword: true, controller: _senhaController),

                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _carregando ? null : _fazerLogin,
                      style: _buttonStyle(),
                      child: _carregando
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("ENTRAR"),
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

// --- TELA PRINCIPAL: DASHBOARD DE FINANÇAS ---
class HomeView extends StatefulWidget {
  final String userName;

  const HomeView({super.key, required this.userName});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // Barra Superior do App
      appBar: AppBar(
        title: Text("Olá, ${widget.userName}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.teal[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              // Desloga e volta para a tela de Login limpa
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          // 1. CARD DE SALDO (BANNER SUPERIOR TEAL)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.teal[700],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("SALDO ATUAL", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 5),
                const Text("R\$ 2.450,00", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                // Linha de Entradas e Saídas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Bloco de Receitas
                    Row(
                      children: [
                        const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.arrow_upward, color: Colors.greenAccent)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("Entradas", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text("R\$ 3.500,00", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    // Bloco de Despesas
                    Row(
                      children: [
                        const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.arrow_downward, color: Colors.orangeAccent)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("Saídas", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text("R\$ 1.050,00", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Título da Seção de Histórico
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Últimas Transações", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text("Ver todas", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 2. LISTA DE TRANSAÇÕES (MOCKADAS POR ENQUANTO)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              children: [
                _buildTransactionTile(title: "Salário", subtitle: "Recebimento mensal", value: "+ R\$ 3.500,00", isIncome: true),
                _buildTransactionTile(title: "Supermercado", subtitle: "Alimentação", value: "- R\$ 450,00", isIncome: false),
                _buildTransactionTile(title: "Posto de Gasolina", subtitle: "Transporte", value: "- R\$ 180,00", isIncome: false),
                _buildTransactionTile(title: "Assinatura Streaming", subtitle: "Lazer", value: "- R\$ 420,00", isIncome: false),
              ],
            ),
          ),
        ],
      ),

      // 3. BOTÃO DE ADICIONAR NOVA TRANSAÇÃO
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Abrir tela ou modal de nova transação
        },
        backgroundColor: Colors.teal[700],
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // Componente visual para cada linha de transação
  Widget _buildTransactionTile({required String title, required String subtitle, required String value, required bool isIncome}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.green[50] : Colors.red[50],
          child: Icon(isIncome ? Icons.attach_money : Icons.shopping_bag, color: isIncome ? Colors.green[700] : Colors.red[700]),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
        trailing: Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isIncome ? Colors.green[700] : Colors.red[700],
          ),
        ),
      ),
    );
  }
}