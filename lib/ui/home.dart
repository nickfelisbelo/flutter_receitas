import 'package:flutter/material.dart';
import '../api.dart';
import 'detalhes.dart';
import 'style/colors.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Receita>> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = ReceitaApi.listar();
  }

  Future<void> _reload() async {
    final future = ReceitaApi.listar();
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {
      // O FutureBuilder apresenta o erro na tela.
    }
  }

  Future<void> _openForm({Receita? receita}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => RecipeFormScreen(receita: receita)),
    );
    if (changed == true && mounted) await _reload();
  }

  Future<void> _deleteRecipe(Receita receita) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir receita?'),
        content: Text(
          'Deseja excluir "${receita.nome}"? Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ReceitaApi.excluir(receita);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receita excluída com sucesso.')),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
    }
  }

  Future<void> _showDetails(Receita receita) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
          child: RecipeDetailContent(
            receita: receita,
            onClose: () => Navigator.pop(dialogContext),
            onEdit: () {
              Navigator.pop(dialogContext);
              _openForm(receita: receita);
            },
            onDelete: () {
              Navigator.pop(dialogContext);
              _deleteRecipe(receita);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Receitas',
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Alternar tema',
            onPressed: widget.onToggleTheme,
            icon: const Icon(Icons.contrast_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(22),
                child: Row(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      color: AppColors.spotifyGreen,
                      size: 32,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Receitas',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Início'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: const Text('Tema claro/escuro'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onToggleTheme();
                },
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Receitas • feito com Flutter',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova receita'),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Receita>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.spotifyGreen),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 100),
                  const Icon(Icons.cloud_off_rounded, size: 58),
                  const SizedBox(height: 12),
                  const Text(
                    'Não foi possível carregar as receitas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 18),
                  Center(
                    child: FilledButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ),
                ],
              );
            }

            final recipes = (snapshot.data ?? [])
                .where(
                  (r) => r.nome.toLowerCase().contains(_search.toLowerCase()),
                )
                .toList();

            if (recipes.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 100),
                  const Icon(Icons.menu_book_rounded, size: 58),
                  const SizedBox(height: 12),
                  const Text(
                    'Nenhuma receita encontrada.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tente outra busca ou cadastre uma nova receita.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) => setState(() => _search = value),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar receita...',
                      isDense: true,
                    ),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              children: [
                Text(
                  'ENCONTRE SUA PRÓXIMA RECEITA',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  onChanged: (value) => setState(() => _search = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar receita...',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 20),
                ...recipes.map(
                  (recipe) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _showDetails(recipe),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                ReceitaImage(
                                  url: recipe.imagemUrl,
                                  height: 190,
                                  width: double.infinity,
                                  borderRadius: BorderRadius.zero,
                                ),
                                Positioned(
                                  left: 12,
                                  top: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 11,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.spotifyGreen,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      recipe.tipo.toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                14,
                                12,
                                12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          recipe.nome,
                                          style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          recipe.custo.isEmpty
                                              ? 'Toque para ver os detalhes'
                                              : 'Custo aproximado: R\$ ${recipe.custo}',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Editar receita',
                                    onPressed: () => _openForm(receita: recipe),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Excluir receita',
                                    onPressed: () => _deleteRecipe(recipe),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class RecipeFormScreen extends StatefulWidget {
  final Receita? receita;

  const RecipeFormScreen({super.key, this.receita});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _ingredientes = TextEditingController();
  final _preparo = TextEditingController();
  final _imagem = TextEditingController();
  final _custo = TextEditingController();
  String _tipo = 'DOCE';
  bool _saving = false;

  bool get _isEditing => widget.receita != null;

  @override
  void initState() {
    super.initState();
    final receita = widget.receita;
    if (receita != null) {
      _nome.text = receita.nome;
      _ingredientes.text = receita.ingredientes;
      _preparo.text = receita.modoPreparo;
      _imagem.text = receita.imagemUrl;
      _custo.text = receita.custo;
      const tipos = ['DOCE', 'SALGADA', 'BEBIDA'];
      _tipo = tipos.contains(receita.tipo.toUpperCase())
          ? receita.tipo.toUpperCase()
          : 'DOCE';
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _ingredientes.dispose();
    _preparo.dispose();
    _imagem.dispose();
    _custo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final custo = _custo.text.trim();
    if (custo.isNotEmpty &&
        double.tryParse(custo.replaceAll(',', '.')) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um custo numérico válido.')),
      );
      return;
    }

    setState(() => _saving = true);

    final receita = Receita(
      id: widget.receita?.id,
      nome: _nome.text.trim(),
      tipo: _tipo,
      ingredientes: _ingredientes.text.trim(),
      modoPreparo: _preparo.text.trim(),
      imagemUrl: _imagem.text.trim(),
      custo: custo,
    );

    try {
      if (_isEditing) {
        await ReceitaApi.atualizar(receita);
      } else {
        await ReceitaApi.criar(receita);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Receita atualizada com sucesso!'
                : 'Receita cadastrada com sucesso!',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao ${_isEditing ? 'editar' : 'cadastrar'}: $e'),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar receita' : 'Nova receita',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF243D2E),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.spotifyBright,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isEditing
                            ? 'Atualize os dados da sua receita.'
                            : 'Compartilhe sua receita com o mundo.',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _field(
                _nome,
                'Nome da receita',
                Icons.restaurant,
                required: true,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo de receita',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'DOCE', child: Text('Doce')),
                  DropdownMenuItem(value: 'SALGADA', child: Text('Salgada')),
                  DropdownMenuItem(value: 'BEBIDA', child: Text('Bebida')),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _tipo = value ?? 'DOCE'),
              ),
              const SizedBox(height: 14),
              _field(
                _ingredientes,
                'Ingredientes',
                Icons.shopping_basket_outlined,
                required: true,
                maxLines: 4,
              ),
              const SizedBox(height: 14),
              _field(
                _preparo,
                'Modo de preparo',
                Icons.soup_kitchen_outlined,
                required: true,
                maxLines: 5,
              ),
              const SizedBox(height: 14),
              _field(
                _imagem,
                'URL da imagem (opcional)',
                Icons.image_outlined,
                keyboard: TextInputType.url,
              ),
              const SizedBox(height: 14),
              _field(
                _custo,
                'Custo aproximado (opcional)',
                Icons.payments_outlined,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isEditing ? Icons.save_rounded : Icons.check_rounded,
                        ),
                  label: Text(
                    _saving
                        ? 'Enviando...'
                        : (_isEditing
                              ? 'Salvar alterações'
                              : 'Cadastrar receita'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.spotifyGreen,
                    foregroundColor: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 21),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: required
          ? (value) => value == null || value.trim().isEmpty
                ? 'Preencha este campo.'
                : null
          : null,
    );
  }
}
