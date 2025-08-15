import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'calendario_agenda.dart';
import 'contabil.dart';
import 'contas_page.dart';
import 'login_senha.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    CalendarioAgendaPage(),
    ContabilPage(),
    ContasPage(),
  ];

  static const List<String> _widgetTitles = <String>[
    'Agenda',
    'Caixa',
    'Contas',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- NOVAS FUNÇÕES DE NAVEGAÇÃO ---
  void _navigateToPreviousPage() {
    setState(() {
      if (_selectedIndex > 0) {
        _selectedIndex--;
      } else {
        _selectedIndex = _widgetOptions.length - 1; // Volta para a última aba
      }
    });
  }

  void _navigateToNextPage() {
    setState(() {
      if (_selectedIndex < _widgetOptions.length - 1) {
        _selectedIndex++;
      } else {
        _selectedIndex = 0; // Volta para a primeira aba
      }
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_widgetTitles[_selectedIndex], style: TextStyle(color: theme.hintColor)),
        backgroundColor: theme.primaryColor,
        automaticallyImplyLeading: false,
        // --- MUDANÇA AQUI: Adicionadas as setas de navegação ---
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
            tooltip: 'Anterior',
            onPressed: _navigateToPreviousPage,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
            tooltip: 'Próxima',
            onPressed: _navigateToNextPage,
          ),
          const SizedBox(width: 10), // Espaçamento
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Caixa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Contas',
          ),
        ],
        currentIndex: _selectedIndex,
        backgroundColor: theme.primaryColor,
        selectedItemColor: theme.hintColor,
        unselectedItemColor: Colors.white70,
        onTap: _onItemTapped,
      ),
    );
  }
}
