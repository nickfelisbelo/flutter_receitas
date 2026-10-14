import 'dart:convert';
import 'package:http/http.dart' as http;

class Receita {
  final dynamic id;
  final String nome;
  final String tipo;
  final String ingredientes;
  final String modoPreparo;
  final String imagemUrl;
  final String custo;

  const Receita({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.ingredientes,
    required this.modoPreparo,
    required this.imagemUrl,
    required this.custo,
  });

  factory Receita.fromJson(Map<String, dynamic> json) {
    String value(List<String> keys, [String fallback = '']) {
      for (final key in keys) {
        final item = json[key];
        if (item != null) return item.toString();
      }
      return fallback;
    }

    return Receita(
      id: json['id'] ?? json['_id'] ?? json['receitaId'],
      nome: value(['nome', 'name', 'titulo', 'title'], 'Receita sem nome'),
      tipo: value(['tipo', 'type', 'categoria', 'category'], 'Outros'),
      ingredientes: value(['ingredientes', 'ingredients']),
      modoPreparo: value([
        'modoFazer',
        'modoPreparo',
        'modo_de_preparo',
        'modo de fazer',
        'preparo',
        'instructions',
      ]),
      imagemUrl: value([
        'img',
        'urlImagem',
        'imagem',
        'image',
        'imageUrl',
        'url',
        'foto',
      ]),
      custo: value(['custoAproximado', 'custo', 'cost']),
    );
  }

  Map<String, dynamic> toJson() {
    final parsedCost = double.tryParse(custo.trim().replaceAll(',', '.'));
    return {
      'nome': nome,
      'tipo': tipo,
      'ingredientes': ingredientes,
      'modoFazer': modoPreparo,
      'img': imagemUrl,
      if (custo.trim().isNotEmpty)
        'custoAproximado': parsedCost ?? custo.trim(),
    };
  }
}

class ReceitaApi {
  static const String baseUrl = 'https://receitasapi-b-2025.vercel.app';

  static Uri _receitasUri() => Uri.parse('$baseUrl/receitas');

  static Exception _apiError(String operation, http.Response response) {
    final body = response.body.trim();
    final detail = body.isEmpty ? 'sem detalhes do servidor' : body;
    return Exception('$operation. HTTP ${response.statusCode}: $detail');
  }

  static Future<List<Receita>> listar() async {
    final response = await http
        .get(_receitasUri(), headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _apiError('Erro ao buscar receitas', response);
    }

    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final List<dynamic> items;

    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final candidate =
          decoded['receitas'] ??
          decoded['data'] ??
          decoded['results'] ??
          decoded['items'];
      if (candidate is List) {
        items = candidate;
      } else {
        throw const FormatException(
          'A resposta da API não contém uma lista de receitas.',
        );
      }
    } else {
      throw const FormatException('Formato da resposta não reconhecido.');
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(Receita.fromJson)
        .toList();
  }

  static Future<void> criar(Receita receita) async {
    final response = await http
        .post(
          _receitasUri(),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': 'application/json',
          },
          body: jsonEncode(receita.toJson()),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _apiError('Não foi possível cadastrar', response);
    }
  }

  static Future<void> atualizar(Receita receita) async {
    if (receita.id == null) {
      throw Exception('A receita não possui ID para edição.');
    }

    final response = await http
        .put(
          Uri.parse(
            '$baseUrl/receitas/${Uri.encodeComponent(receita.id.toString())}',
          ),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': 'application/json',
          },
          body: jsonEncode(receita.toJson()),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _apiError('Não foi possível editar', response);
    }
  }

  static Future<void> excluir(Receita receita) async {
    if (receita.id == null) {
      throw Exception('A receita não possui ID para exclusão.');
    }

    final response = await http
        .delete(
          Uri.parse(
            '$baseUrl/receitas/${Uri.encodeComponent(receita.id.toString())}',
          ),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _apiError('Não foi possível excluir', response);
    }
  }
}
