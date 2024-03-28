import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'pagina_amico.dart';

class CercaUtentiPage extends StatefulWidget {
  const CercaUtentiPage({Key? key}) : super(key: key);

  @override
  _CercaUtentiPageState createState() => _CercaUtentiPageState();
}

class _CercaUtentiPageState extends State<CercaUtentiPage> {
  late final TextEditingController _searchController;
  late final DatabaseReference _databaseRef;
  Map<String, dynamic> _users = {};
  List<String> _name = [];
  int? _selectedIndex; // Indice dell'elemento selezionato

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _databaseRef = FirebaseDatabase.instance.reference().child('users');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Cerca utenti
  void searchUsers(String query) async {
    try {
      if (query.isEmpty) {
        _name.clear(); // Se il campo di ricerca è vuoto, svuota la lista
        _users.clear();
        setState(() {});
        return;
      }

      final DataSnapshot snapshot = (await _databaseRef.once()).snapshot;
      final Map<dynamic, dynamic>? users = snapshot.value as Map<dynamic, dynamic>?;

      if (users != null) {
        _name.clear();
        _users.clear();
        users.forEach((userId, userData) {
          if (userData['name'] != null && userData['name'].toString().toLowerCase().contains(query.toLowerCase())) {
            final profileImage = userData['profile image'] ?? '';
            _name.add(userData['name']);
            _users[userData['name']] = {
              'userId': userId,
              'profileImage': profileImage,
            };
            print('Immagine di profilo per ${userData['name']}: $profileImage');
          }
        });
        setState(() {});
      }
    } catch (e) {
      print('Errore durante il recupero dei dati: $e');

    }
  }


  void navigateToFriendPage(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaginaAmico(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('See Your Music'),
        actions: [],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Inserisci il nome dell\'utente',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _name.clear();
                      _users.clear();
                    });
                  },
                ) : null,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              onChanged: searchUsers,
            ),
          ),
          Expanded(
            child: _name.isNotEmpty ? ListView.builder(
              itemCount: _name.length,
              itemBuilder: (context, index) {
                final name = _name[index];
                final profileImage = _users[name]['profileImage'];
                return GestureDetector(
                  onTap: () {
                    print('Hai cliccato su $name');
                    // Recupera l'userId associato al nome selezionato
                    final userId = _users[name]['userId'];
                    if (userId != null) {
                      print('L\'userId associato a $name è $userId');
                      navigateToFriendPage(context, userId);
                    } else {
                      print('UserId non trovato per $name');
                    }
                  },
                  child: ListTile(
                    title: Text(name),
                    leading: profileImage != null && profileImage.isNotEmpty
                        ? CircleAvatar(
                      backgroundColor: profileImage != null
                      ? Colors.grey[800] : Colors.transparent,
                      backgroundImage: NetworkImage(profileImage),
                    )
                        : CircleAvatar(
                      backgroundColor: Colors.grey[800],
                      // Imposta un'immagine di default se l'utente non ha un'immagine di profilo
                      child: Icon(Icons.account_circle, color: Colors.white),
                    ),
                    tileColor: _selectedIndex == index ? Colors.blue.withOpacity(0.5) : null,

                  ),
                );
              },
            ) : _searchController.text.isNotEmpty // Controlla se il campo di ricerca non è vuoto
              ? Center(
                child: Text('Nessun utente trovato'),
            )
                : SizedBox(),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    title: 'Cerca Utenti',
    home: CercaUtentiPage(),
  ));
}
