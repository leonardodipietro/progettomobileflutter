import 'package:flutter/material.dart';

class CercaUtentiPage extends StatelessWidget {
  const CercaUtentiPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cerca Utenti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Azioni da eseguire quando viene premuto il pulsante di ricerca
            },
          ),
        ],
        // Imposta l'icona del bottone come bianca
        iconTheme: IconThemeData(color: Colors.black),
        // Aggiungi il campo di ricerca nella parte destra della AppBar
        // utilizzando un widget TextField
        // In alternativa, puoi creare un nuovo widget per la barra di ricerca e sostituire il TextField con esso
        // per una maggiore personalizzazione e flessibilità
        actionsIconTheme: IconThemeData(color: Colors.white),
        flexibleSpace: TextField(
          decoration: InputDecoration(
            hintText: 'Cerca...',
            hintStyle: TextStyle(color: Colors.white),
            border: InputBorder.none,
            contentPadding: EdgeInsets.only(right: 56.0),
          ),
          style: TextStyle(color: Colors.white),
        ),
      ),
      //backgroundColor: Colors.black, // Imposta il colore di sfondo della pagina su nero
      // Utilizza il widget della barra di navigazione dal file navigation_bar.dart
    );
  }
}
