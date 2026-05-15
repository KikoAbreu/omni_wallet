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

    // Validação visual
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
              builder: (context) => HomeView(
                userName: resposta['nome'] ?? 'Usuário',
                userEmail: email,
              ),
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
  final String userEmail; // Novo campo para o e-mail

  const HomeView({super.key, required this.userName, required this.userEmail});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  double saldo = 0.0;
  double entradas = 0.0;
  double saidas = 0.0;
  List<dynamic> transacoes = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _buscarDados();
  }

  // Busca transações do banco e calcula os totais
  Future<void> _buscarDados() async {
    setState(() => carregando = true);
    try {
      final dados = await Supabase.instance.client
          .from('transacoes')
          .select()
          .eq('usuario_email', widget.userEmail)
          .order('created_at', ascending: false);

      double totalEntradas = 0;
      double totalSaidas = 0;

      for (var item in dados) {
        double valor = (item['valor'] as num).toDouble();
        if (item['is_entrada'] == true) {
          totalEntradas += valor;
        } else {
          totalSaidas += valor;
        }
      }

      setState(() {
        transacoes = dados;
        entradas = totalEntradas;
        saidas = totalSaidas;
        saldo = totalEntradas - totalSaidas;
        carregando = false;
      });
    } catch (e) {
      print("Erro ao buscar dados: $e");
      setState(() => carregando = false);
    }
  }

  // Função para abrir o formulário de nova transação
  void _abrirFormulario() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: FormularioTransacao(
          userEmail: widget.userEmail,
          onSalvar: _buscarDados, // Atualiza a lista após salvar
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Olá, ${widget.userName}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.teal[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginView())),
          )
        ],
      ),
      body: Column(
        children: [
          // CARD DE SALDO REAL
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.teal[700],
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("SALDO ATUAL", style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 5),
                Text("R\$ ${saldo.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _resumoTile("Entradas", entradas, Colors.greenAccent, Icons.arrow_upward),
                    _resumoTile("Saídas", saidas, Colors.orangeAccent, Icons.arrow_downward),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // LISTA DE TRANSAÇÕES REAIS
          Expanded(
            child: carregando
                ? const Center(child: CircularProgressIndicator())
                : transacoes.isEmpty
                ? const Center(child: Text("Nenhuma transação encontrada."))
                : RefreshIndicator(
              onRefresh: _buscarDados,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: transacoes.length,
                itemBuilder: (context, index) {
                  final t = transacoes[index];
                  return _buildTransactionTile(
                    id: t['id'],
                    title: t['titulo'],
                    subtitle: t['descricao'] ?? "",
                    value: "${t['is_entrada'] ? '+ ' : '- '}R\$ ${(t['valor'] as num).toDouble().toStringAsFixed(2)}",
                    isIncome: t['is_entrada'],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        backgroundColor: Colors.teal[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _resumoTile(String label, double valor, Color cor, IconData icon) {
    return Row(
      children: [
        CircleAvatar(backgroundColor: Colors.white24, child: Icon(icon, color: cor, size: 20)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text("R\$ ${valor.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionTile({required int id, required String title, required String subtitle, required String value, required bool isIncome}) {
    return Dismissible(
      key: Key(id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        await Supabase.instance.client.from('transacoes').delete().eq('id', id);
        _buscarDados();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isIncome ? Colors.green[50] : Colors.red[50],
            child: Icon(isIncome ? Icons.attach_money : Icons.shopping_bag, color: isIncome ? Colors.green[700] : Colors.red[700]),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          trailing: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.green[700] : Colors.red[700])),
        ),
      ),
    );
  }
}


class FormularioTransacao extends StatefulWidget {
  final String userEmail;
  final VoidCallback onSalvar;

  const FormularioTransacao({super.key, required this.userEmail, required this.onSalvar});

  @override
  State<FormularioTransacao> createState() => _FormularioTransacaoState();
}

class _FormularioTransacaoState extends State<FormularioTransacao> {
  final _tituloController = TextEditingController();
  final _valorController = TextEditingController();
  final _descController = TextEditingController();
  bool _isEntrada = true;
  bool _salvando = false;

  Future<void> _salvar() async {
    if (_tituloController.text.isEmpty || _valorController.text.isEmpty) return;

    setState(() => _salvando = true);
    try {
      await Supabase.instance.client.from('transacoes').insert({
        'usuario_email': widget.userEmail,
        'titulo': _tituloController.text,
        'descricao': _descController.text,
        'valor': double.parse(_valorController.text.replaceAll(',', '.')),
        'is_entrada': _isEntrada,
      });
      widget.onSalvar();
      Navigator.pop(context);
    } catch (e) {
      print("Erro ao salvar: $e");
    } finally {
      setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Nova Transação", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(controller: _tituloController, decoration: const InputDecoration(labelText: "Título (ex: Salário)")),
          TextField(controller: _descController, decoration: const InputDecoration(labelText: "Descrição (opcional)")),
          TextField(controller: _valorController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Valor (R\$)")),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text("Tipo: "),
              ChoiceChip(label: const Text("Entrada"), selected: _isEntrada, onSelected: (val) => setState(() => _isEntrada = true)),
              const SizedBox(width: 10),
              ChoiceChip(label: const Text("Saída"), selected: !_isEntrada, onSelected: (val) => setState(() => _isEntrada = false)),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _salvando ? null : _salvar,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.teal),
            child: _salvando ? const CircularProgressIndicator(color: Colors.white) : const Text("SALVAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}