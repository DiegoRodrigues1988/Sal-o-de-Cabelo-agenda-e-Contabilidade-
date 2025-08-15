import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:collection';

// Classe para representar uma conta
class Conta {
  final String id;
  final String descricao;
  final double valor;
  final String tipo; // 'pagar' ou 'receber'

  Conta({required this.id, required this.descricao, required this.valor, required this.tipo});

  factory Conta.fromFirestore(Map<String, dynamic> doc, String docId) {
    return Conta(
      id: docId,
      descricao: doc['descricao'] ?? '',
      valor: (doc['valor'] as num).toDouble(),
      tipo: doc['tipo'] ?? 'pagar',
    );
  }
}

class ContasPage extends StatefulWidget {
  const ContasPage({super.key});

  @override
  State<ContasPage> createState() => _ContasPageState();
}

class _ContasPageState extends State<ContasPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final LinkedHashMap<DateTime, List<Conta>> _contas = LinkedHashMap(
    equals: isSameDay,
    hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
  );

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _carregarContasDoFirestore();
  }

  void _carregarContasDoFirestore() {
    FirebaseFirestore.instance.collection('contas').snapshots().listen((snapshot) {
      final Map<DateTime, List<Conta>> contasCarregadas = {};
      for (var doc in snapshot.docs) {
        final conta = Conta.fromFirestore(doc.data(), doc.id);
        final diaDoVencimento = (doc.data()['vencimento'] as Timestamp).toDate();
        final diaNormalizado = DateTime(diaDoVencimento.year, diaDoVencimento.month, diaDoVencimento.day);

        if (contasCarregadas[diaNormalizado] == null) {
          contasCarregadas[diaNormalizado] = [];
        }
        contasCarregadas[diaNormalizado]!.add(conta);
      }
      setState(() {
        _contas.clear();
        _contas.addAll(contasCarregadas);
      });
    });
  }

  List<Conta> _getContasForDay(DateTime day) {
    return _contas[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  Future<void> _adicionarConta(String descricao, double valor, String tipo) async {
    if (_selectedDay == null) return;
    await FirebaseFirestore.instance.collection('contas').add({
      'descricao': descricao,
      'valor': valor,
      'tipo': tipo,
      'vencimento': Timestamp.fromDate(_selectedDay!),
    });
  }

  Future<void> _removerConta(String contaId) async {
    await FirebaseFirestore.instance.collection('contas').doc(contaId).delete();
  }

  void _mostrarDialogoDeAdicionarConta() {
    final descricaoController = TextEditingController();
    final valorController = TextEditingController();
    String tipoSelecionado = 'pagar';

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text('Nova Conta', style: TextStyle(color: Theme.of(context).hintColor)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: descricaoController, decoration: const InputDecoration(labelText: 'Descrição da Conta')),
                  TextField(controller: valorController, decoration: const InputDecoration(labelText: 'Valor'), keyboardType: TextInputType.number),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('A Pagar', style: TextStyle(color: Colors.redAccent)),
                      Switch(
                        value: tipoSelecionado == 'receber',
                        onChanged: (value) {
                          setDialogState(() {
                            tipoSelecionado = value ? 'receber' : 'pagar';
                          });
                        },
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.red,
                      ),
                      const Text('A Receber', style: TextStyle(color: Colors.greenAccent)),
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
                      _adicionarConta(descricaoController.text, valor, tipoSelecionado);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contasDoDia = _getContasForDay(_selectedDay!);

    return Scaffold(
      // A AppBar foi removida, pois agora é controlada pela HomePage
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoDeAdicionarConta,
        backgroundColor: theme.hintColor,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Column(
        children: [
          TableCalendar<Conta>(
            locale: 'pt_BR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            eventLoader: _getContasForDay,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: events.map((event) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: event.tipo == 'receber' ? Colors.greenAccent : Colors.redAccent,
                    ),
                  )).toList(),
                );
              },
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.hintColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          // --- MUDANÇA AQUI ---
          Text('Contas a pagar e a receber', style: theme.textTheme.headlineSmall),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: contasDoDia.length,
              itemBuilder: (context, index) {
                final conta = contasDoDia[index];
                final isReceber = conta.tipo == 'receber';
                return Card(
                  color: theme.colorScheme.surface,
                  child: ListTile(
                    leading: Icon(
                      isReceber ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isReceber ? Colors.greenAccent : Colors.redAccent,
                    ),
                    title: Text(conta.descricao),
                    subtitle: Text('R\$ ${conta.valor.toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red[200]),
                      onPressed: () => _removerConta(conta.id),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
