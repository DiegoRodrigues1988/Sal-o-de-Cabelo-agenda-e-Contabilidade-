import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:collection';

class Evento {
  final String id;
  final String titulo;
  final String cliente;
  final String hora;

  Evento({required this.id, required this.titulo, required this.cliente, required this.hora});

  factory Evento.fromFirestore(Map<String, dynamic> doc, String docId) {
    return Evento(
      id: docId,
      titulo: doc['titulo'] ?? '',
      cliente: doc['cliente'] ?? '',
      hora: doc['hora'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'titulo': titulo,
      'cliente': cliente,
      'hora': hora,
    };
  }

  @override
  String toString() => titulo;
}

class CalendarioAgendaPage extends StatefulWidget {
  const CalendarioAgendaPage({super.key});

  @override
  State<CalendarioAgendaPage> createState() => _CalendarioAgendaPageState();
}

class _CalendarioAgendaPageState extends State<CalendarioAgendaPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final LinkedHashMap<DateTime, List<Evento>> _eventos = LinkedHashMap(
    equals: isSameDay,
    hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
  );

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _carregarEventosDoFirestore();
  }

  void _carregarEventosDoFirestore() {
    FirebaseFirestore.instance.collection('agendamentos').snapshots().listen((snapshot) {
      final Map<DateTime, List<Evento>> eventosCarregados = {};
      for (var doc in snapshot.docs) {
        final evento = Evento.fromFirestore(doc.data(), doc.id);
        final diaDoEvento = (doc.data()['dia'] as Timestamp).toDate();
        final diaNormalizado = DateTime(diaDoEvento.year, diaDoEvento.month, diaDoEvento.day);

        if (eventosCarregados[diaNormalizado] == null) {
          eventosCarregados[diaNormalizado] = [];
        }
        eventosCarregados[diaNormalizado]!.add(evento);
      }
      setState(() {
        _eventos.clear();
        _eventos.addAll(eventosCarregados);
      });
    });
  }

  List<Evento> _getEventsForDay(DateTime day) {
    return _eventos[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  Future<void> _adicionarEvento(String titulo, String cliente, String hora) async {
    if (_selectedDay == null) return;
    final novoEvento = Evento(id: '', titulo: titulo, cliente: cliente, hora: hora);
    await FirebaseFirestore.instance.collection('agendamentos').add({
      ...novoEvento.toFirestore(),
      'dia': Timestamp.fromDate(_selectedDay!),
    });
  }

  Future<void> _removerEvento(String eventoId) async {
    await FirebaseFirestore.instance.collection('agendamentos').doc(eventoId).delete();
  }

  void _mostrarDialogoDeAdicionarEvento() {
    final tituloController = TextEditingController();
    final clienteController = TextEditingController();
    final horaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text('Novo Agendamento', style: TextStyle(color: Theme.of(context).hintColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: clienteController, decoration: const InputDecoration(labelText: 'Nome do Cliente')),
              TextField(controller: tituloController, decoration: const InputDecoration(labelText: 'Serviço (Ex: Corte)')),
              TextField(controller: horaController, decoration: const InputDecoration(labelText: 'Hora (Ex: 14:30)')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                if (clienteController.text.isNotEmpty && tituloController.text.isNotEmpty && horaController.text.isNotEmpty) {
                  _adicionarEvento(
                    tituloController.text,
                    clienteController.text,
                    horaController.text,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoDeRemoverEvento(Evento evento) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Confirmar Exclusão', style: TextStyle(color: Theme.of(context).hintColor)),
        content: Text('Tem certeza que deseja remover o agendamento de ${evento.cliente}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _removerEvento(evento.id);
              Navigator.of(context).pop();
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventosDoDia = _getEventsForDay(_selectedDay!);

    return Scaffold(
      // A AppBar foi removida daqui
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoDeAdicionarEvento,
        backgroundColor: theme.hintColor,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Column(
        children: [
          TableCalendar<Evento>(
            locale: 'pt_BR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            eventLoader: _getEventsForDay,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(color: theme.hintColor, fontSize: 18.0),
              leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: const TextStyle(color: Colors.white),
              weekendTextStyle: const TextStyle(color: Colors.white70),
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.hintColor,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              markerDecoration: const BoxDecoration(
                color: Color(0xFFC0C0C0),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Compromissos do dia',
              style: theme.textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: eventosDoDia.length,
              itemBuilder: (context, index) {
                final evento = eventosDoDia[index];
                return Card(
                  color: theme.colorScheme.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.hintColor,
                      child: Text(
                          evento.hora,
                          style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)
                      ),
                    ),
                    title: Text(evento.cliente, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text(evento.titulo, style: const TextStyle(color: Color(0xFFE0E1DD))),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red[200]),
                      onPressed: () => _mostrarDialogoDeRemoverEvento(evento),
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
