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
    setState(() => _future = ReceitaApi.listar());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receitas', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
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
                child: Row(children: [
                  Icon(Icons.restaurant_menu, color: AppColors.spotifyGreen, size: 32),
                  SizedBox(width: 12),
                  Text('Receitas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ]),
              ),
              const Divider(),
              ListTile(leading: const Icon(Icons.home_outlined), title: const Text('Início'), onTap: () => Navigator.pop(context)),
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
                child: Text('Receitas • feito com Flutter', textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const RecipeFormScreen()));
          if (created == true && mounted) _reload();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova receita'),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Receita>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.spotifyGreen));
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 100),
                  const Icon(Icons.cloud_off_rounded, size: 58),
                  const SizedBox(height: 12),
                  const Text('Não foi possível carregar as receitas.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 18),
                  Center(child: FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente'))),
                ],
              );
            }

            final recipes = (snapshot.data ?? []).where((r) => r.nome.toLowerCase().contains(_search.toLowerCase())).toList();
            if (recipes.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 100),
                  const Icon(Icons.menu_book_rounded, size: 58),
                  const SizedBox(height: 12),
                  const Text('Nenhuma receita encontrada.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Tente outra busca ou cadastre uma nova receita.', textAlign: TextAlign.center),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              children: [
                Text('ENCONTRE SUA PRÓXIMA RECEITA', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                const SizedBox(height: 14),
                TextField(
                  onChanged: (value) => setState(() => _search = value),
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar receita...', isDense: true),
                ),
                const SizedBox(height: 20),
                ...recipes.map((recipe) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (dialogContext) => Dialog(
                          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          clipBehavior: Clip.antiAlias,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
                            child: RecipeDetailContent(
                              receita: recipe,
                              onClose: () => Navigator.pop(dialogContext),
                            ),
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ReceitaImage(url: recipe.imagemUrl, height: 190, width: double.infinity, borderRadius: BorderRadius.zero),
                              Positioned(
                                left: 12, top: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                  decoration: BoxDecoration(color: AppColors.spotifyGreen, borderRadius: BorderRadius.circular(30)),
                                  child: Text(recipe.tipo.toUpperCase(), style: const TextStyle(color: AppColors.black, fontSize: 10, fontWeight: FontWeight.w900)),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                            child: Row(
                              children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(recipe.nome, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 5),
                                  Text(recipe.custo.isEmpty ? 'Toque para ver os detalhes' : 'Custo aproximado: R\$ ${recipe.custo}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                                ])),
                                IconButton(
                                  tooltip: 'Visualizar',
                                  onPressed: () => showDialog<void>(
                                    context: context,
                                    builder: (dialogContext) => Dialog(
                                      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                                      clipBehavior: Clip.antiAlias,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
                                        child: RecipeDetailContent(
                                          receita: recipe,
                                          onClose: () => Navigator.pop(dialogContext),
                                        ),
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.arrow_forward_rounded),
                                  style: IconButton.styleFrom(backgroundColor: AppColors.spotifyGreen, foregroundColor: AppColors.black),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
              ],
            );
          },
        ),
      ),
    );
  }
}


class RecipeFormScreen extends StatefulWidget {
  const RecipeFormScreen({super.key});

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
    setState(() => _saving = true);
    try {
      await ReceitaApi.criar(Receita(
        id: null,
        nome: _nome.text.trim(),
        tipo: _tipo,
        ingredientes: _ingredientes.text.trim(),
        modoPreparo: _preparo.text.trim(),
        imagemUrl: _imagem.text.trim(),
        custo: _custo.text.trim(),
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receita cadastrada com sucesso!')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao cadastrar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova receita', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: const Color(0xFF243D2E), borderRadius: BorderRadius.circular(18)),
                child: const Row(children: [
                  Icon(Icons.auto_awesome_rounded, color: AppColors.spotifyBright, size: 28),
                  SizedBox(width: 12),
                  Expanded(child: Text('Compartilhe sua receita com o mundo.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                ]),
              ),
              const SizedBox(height: 24),
              _field(_nome, 'Nome da receita', Icons.restaurant, required: true),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo de receita', prefixIcon: Icon(Icons.category_outlined)),
                items: const [
                  DropdownMenuItem(value: 'DOCE', child: Text('Doce')),
                  DropdownMenuItem(value: 'SALGADA', child: Text('Salgada')),
                  DropdownMenuItem(value: 'BEBIDA', child: Text('Bebida')),
                  DropdownMenuItem(value: 'OUTROS', child: Text('Outros')),
                ],
                onChanged: (value) => setState(() => _tipo = value ?? 'DOCE'),
              ),
              const SizedBox(height: 14),
              _field(_ingredientes, 'Ingredientes', Icons.shopping_basket_outlined, required: true, maxLines: 4),
              const SizedBox(height: 14),
              _field(_preparo, 'Modo de preparo', Icons.soup_kitchen_outlined, required: true, maxLines: 5),
              const SizedBox(height: 14),
              _field(_imagem, 'URL da imagem (opcional)', Icons.image_outlined, keyboard: TextInputType.url),
              const SizedBox(height: 14),
              _field(_custo, 'Custo aproximado (opcional)', Icons.payments_outlined, keyboard: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_rounded),
                  label: Text(_saving ? 'Enviando...' : 'Cadastrar receita', style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.spotifyGreen, foregroundColor: AppColors.black),
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
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 21), alignLabelWithHint: maxLines > 1),
      validator: required ? (value) => value == null || value.trim().isEmpty ? 'Preencha este campo.' : null : null,
    );
  }
}
