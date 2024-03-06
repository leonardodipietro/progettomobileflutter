import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'dart:async';

class ProfiloPersonale extends StatefulWidget {
  const ProfiloPersonale({Key? key}) : super(key: key);

  @override
  _ProfiloPersonaleState createState() => _ProfiloPersonaleState();
}

class _ProfiloPersonaleState extends State<ProfiloPersonale> {
  bool _isLoggedIn = false;
  late StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    // Verifica lo stato di autenticazione all'inizio
    checkUserLoggedIn();
  }

  // Funzione per verificare se l'utente è già autenticato
  void checkUserLoggedIn() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // Se l'utente è autenticato, imposta _isLoggedIn su true
        setState(() {
          _isLoggedIn = true;
        });
      } else {
        // Se l'utente non è autenticato, imposta _isLoggedIn su false
        setState(() {
          _isLoggedIn = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel(); // Rimuovi il listener
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo Personale'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => _signOut(context),
              child: Text('Sign Out'),
            ),
            ElevatedButton(
              onPressed: () => _deleteAccount(context),
              child: Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }

  // Funzione per il sign-out
  void _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Reset dello stato dell'autenticazione
      setState(() {
        _isLoggedIn = false;
      });
      // Navigazione alla pagina di registrazione
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RegistrationPage()),
      );
    } catch (e) {
      // Gestione degli errori
      print('Errore durante il sign-out: $e');
    }
  }

  // Funzione per eliminare l'account
  void _deleteAccount(BuildContext context) async {
    try {
      // Ottieni l'utente attualmente autenticato
      User? user = FirebaseAuth.instance.currentUser;

      // Chiedi conferma all'utente prima di procedere con l'eliminazione dell'account
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Conferma"),
            content: const Text("Sei sicuro di voler eliminare completamente il tuo account? Questa azione non può essere annullata."),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // Chiudi il dialog e ritorna false
                },
                child: const Text("Annulla"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // Chiudi il dialog e ritorna true
                },
                child: const Text("Elimina"),
              ),
            ],
          );
        },
      );

      // Se l'utente ha confermato l'eliminazione, procedi con la rimozione dell'account
      if (confirm == true) {
        // Elimina l'account dell'utente
        await user?.delete();

        // Dopo l'eliminazione dell'account, puoi navigare l'utente alla pagina di login o ad altre schermate
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RegistrationPage()), // Esempio di navigazione alla pagina di login
        );
      }
    } catch (e) {
      // Gestisci eventuali errori durante l'eliminazione dell'account
      print('Errore durante l\'eliminazione dell\'account: $e');
    }
  }
}