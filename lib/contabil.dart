import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class ContabilPage extends StatefulWidget {
  const ContabilPage({super.key});

  @override
  State<ContabilPage> createState() => _ContabilPageState();
}

class _ContabilPageState extends State<ContabilPage> {
  Future<void> _removerTransacao(String docId) async {
    await FirebaseFirestore.instance.collection('transacoes').doc(docId).delete();
  }

  void _mostrarDialogoDeRemoverTransacao(String docId, String descricao) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Confirmar Exclusão', style: TextStyle(color: Theme.of(context).hintColor)),
        content: Text('Tem certeza que deseja remover a transação "$descricao"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _removerTransacao(docId);
              Navigator.of(context).pop();
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  Future<void> _adicionarTransacao(String descricao, double valor, String tipo) async {
    await FirebaseFirestore.instance.collection('transacoes').add({
      'descricao': descricao,
      'valor': valor,
      'tipo': tipo,
      'data': Timestamp.now(),
    });
  }

  void _mostrarDialogoDeAdicionarTransacao() {
    final descricaoController = TextEditingController();
    final valorController = TextEditingController();
    String tipoSelecionado = 'entrada';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text('Nova Transação', style: TextStyle(color: Theme.of(context).hintColor)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: descricaoController, decoration: const InputDecoration(labelText: 'Descrição')),
                  TextField(controller: valorController, decoration: const InputDecoration(labelText: 'Valor'), keyboardType: TextInputType.number),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Saída'),
                      Switch(
                        value: tipoSelecionado == 'entrada',
                        onChanged: (value) {
                          setDialogState(() {
                            tipoSelecionado = value ? 'entrada' : 'saida';
                          });
                        },
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.red,
                      ),
                      const Text('Entrada'),
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    final valor = double.tryParse(valorController.text) ?? 0;
                    if (descricaoController.text.isNotEmpty && valor > 0) {
                      _adicionarTransacao(descricaoController.text, valor, tipoSelecionado);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        // --- MUDANÇA AQUI ---
        title: Text('Caixa', style: TextStyle(color: theme.hintColor)),
        backgroundColor: theme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle, color: theme.hintColor, size: 30),
            onPressed: _mostrarDialogoDeAdicionarTransacao,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('transacoes').orderBy('data', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          double totalEntradas = 0;
          double totalSaidas = 0;
          final transacoes = snapshot.data!.docs;

          for (var doc in transacoes) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['tipo'] == 'entrada') {
              totalEntradas += (data['valor'] as num).toDouble();
            } else {
              totalSaidas += (data['valor'] as num).toDouble();
            }
          }

          final saldo = totalEntradas - totalSaidas;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.8,
                  children: [
                    _buildInfoCard('Entradas', totalEntradas, Icons.arrow_upward, Colors.green),
                    _buildInfoCard('Saídas', totalSaidas, Icons.arrow_downward, Colors.red),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoCard('Saldo Atual', saldo, Icons.account_balance_wallet, theme.hintColor, isFullWidth: true),
                const SizedBox(height: 30),

                Text('Gráfico de Movimentações', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 20),
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: max(max(totalEntradas, totalSaidas), saldo.abs()) * 1.2,
                      barGroups: [
                        _makeBarGroup(0, totalEntradas, Colors.green),
                        _makeBarGroup(1, totalSaidas, Colors.red),
                        _makeBarGroup(2, saldo < 0 ? 0 : saldo, theme.hintColor),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: _bottomTitles)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                Text('Histórico', style: theme.textTheme.headlineSmall),
                ...transacoes.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final isEntrada = data['tipo'] == 'entrada';
                  return Card(
                    color: theme.colorScheme.surface.withAlpha(128),
                    margin: const EdgeInsets.only(top: 10),
                    child: ListTile(
                      leading: Icon(isEntrada ? Icons.arrow_upward : Icons.arrow_downward, color: isEntrada ? Colors.green : Colors.red),
                      title: Text(data['descricao']),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format((data['data'] as Timestamp).toDate())),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'R\$ ${(data['valor'] as num).toStringAsFixed(2)}',
                            style: TextStyle(color: isEntrada ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red[200]),
                            onPressed: () => _mostrarDialogoDeRemoverTransacao(doc.id, data['descricao']),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, double value, IconData icon, Color color, {bool isFullWidth = false}) {
    final theme = Theme.of(context);
    final formattedValue = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(formattedValue, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22)),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(toY: y, color: color, width: 22, borderRadius: BorderRadius.circular(4)),
    ]);
  }

  Widget _bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.white70, fontSize: 14);
    String text;
    switch (value.toInt()) {
      case 0:
        text = 'Entradas';
        break;
      case 1:
        text = 'Saídas';
        break;
      case 2:
        text = 'Saldo';
        break;
      default:
        text = '';
        break;
    }
    return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: style));
  }
}
