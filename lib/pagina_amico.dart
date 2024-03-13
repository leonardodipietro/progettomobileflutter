import 'package:flutter/material.dart';
import 'cerca_utenti.dart';
import 'package:firebase_database/firebase_database.dart';

class PaginaAmico extends StatefulWidget {
  final String userId;

  const PaginaAmico({Key? key, required this.userId}) : super(key: key);

  @override
  _PaginaAmicoState createState() => _PaginaAmicoState();
}

class _PaginaAmicoState extends State<PaginaAmico> {
  late Future<String?> _userNameFuture;

  @override
  void initState() {
    super.initState();
    _userNameFuture = fetchUserName(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder(
          future: _userNameFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Caricamento...'); // Mostra un testo di caricamento se la query è in corso
            } else if (snapshot.hasError) {
              return Text('Errore'); // Mostra un testo di errore se si verificano problemi durante il recupero del nome
            } else {
              final userName = snapshot.data as String?;
              return Text(userName ?? 'Nome Amico'); // Utilizza il nome recuperato, o "Nome Amico" come fallback
            }
          },
        ),
      ),
      body: Center(
        child: Text('Dettagli dell\'amico con userId: ${widget.userId}'),
      ),
    );
  }
}


// Recupera il name
Future<String?> fetchUserName(String userId) async {
  try {
    DatabaseReference reference = FirebaseDatabase.instance.reference().child('users').child(userId);
    DataSnapshot snapshot = (await reference.once()).snapshot;
    Map<dynamic, dynamic>? userData = snapshot.value as Map<dynamic, dynamic>?;

    if (userData != null && userData['name'] != null) {
      return userData['name'];
    } else {
      return null; // Se non viene trovato il nome per lo userId specificato
    }
  } catch (e) {
    print('Errore durante il recupero del nome dell\'utente: $e');
    return null; // Gestisci l'errore in modo appropriato
  }
}

void main() {
  runApp(MaterialApp(
    title: 'Cerca Utenti',
    initialRoute: '/',
    routes: {
      '/': (context) => CercaUtentiPage(),
      '/pagina_amico': (context) => PaginaAmico(userId: '',),
    },
  ));
}
