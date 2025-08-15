import 'package:flutter_test/flutter_test.dart';
import 'package:salao_de_cabelo/main.dart'; // Importa o seu main.dart

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Constrói o nosso app.
    // O nome 'MyApp' foi trocado por 'SalaoDeBelezaApp' para corresponder ao seu código.
    await tester.pumpWidget(const SalaoDeBelezaApp());

    // Verifica se o título do salão é encontrado na tela de login.
    expect(find.text('Glamour Studio'), findsOneWidget);
    expect(find.text('Bem-vindo(a) de volta!'), findsOneWidget);
  });
}
