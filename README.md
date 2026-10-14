# Livro de Receitas Flutter

Estrutura do projeto:

```text
lib/
├── ui/
│   ├── style/
│   │   ├── colors.dart
│   │   └── theme.dart
│   ├── detalhes.dart
│   ├── home.dart
│   └── splash.dart
├── api.dart
└── main.dart
```

Ajustes desta versão:
- Corrigidas as referências às cores do tema (`AppColors`).
- Unificado o nome do widget de imagem como `ReceitaImage`.
- Removidos imports e variáveis sem uso.
- Atualizado `DropdownButtonFormField` para usar `initialValue`.

Dependência necessária no `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.6.0
```

API base: `https://receitasapi-b-2025.vercel.app/`.

Os métodos de escrita em `api.dart` assumem `POST /`, `PUT /{id}` e `DELETE /{id}`. Confirme esses endpoints com a implementação real da API.

Se o seu `pubspec.yaml` tiver `assets: - assets/`, mantenha a pasta `assets/` no projeto ou remova essa declaração se não for usar arquivos de assets.
