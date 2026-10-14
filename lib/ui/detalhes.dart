import 'package:flutter/material.dart';
import '../api.dart';

import 'style/colors.dart';

class RecipeDetailContent extends StatelessWidget {
  final Receita receita;
  final VoidCallback onClose;

  const RecipeDetailContent({
    super.key,
    required this.receita,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 10, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Detalhes da receita',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReceitaImage(
                    url: receita.imagemUrl,
                    height: 210,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 16),
                  Text(receita.nome, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.spotifyGreen,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      receita.tipo.toUpperCase(),
                      style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _section(context, Icons.shopping_basket_outlined, 'Ingredientes', receita.ingredientes),
                  const SizedBox(height: 18),
                  _section(context, Icons.soup_kitchen_outlined, 'Modo de preparo', receita.modoPreparo),
                  if (receita.custo.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _section(context, Icons.payments_outlined, 'Custo aproximado', 'R\$ ${receita.custo}'),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, IconData icon, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: AppColors.spotifyGreen),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF303030)
                : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(content.isEmpty ? 'Não informado.' : content, style: const TextStyle(height: 1.5)),
        ),
      ],
    );
  }
}


class ReceitaImage extends StatelessWidget {
  final String url;
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const ReceitaImage({
    super.key,
    required this.url,
    this.height = 150,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  @override
  Widget build(BuildContext context) {
    final valid = url.trim().startsWith('http');
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: width,
        child: valid
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _placeholder(loading: true);
                },
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder({bool loading = false}) => Container(
    color: const Color(0xFF303030),
    alignment: Alignment.center,
    child: loading
        ? const CircularProgressIndicator(color: Color(0xFF1DB954), strokeWidth: 2)
        : const Icon(Icons.restaurant_rounded, size: 42, color: Color(0xFFB3B3B3)),
  );
}
