import 'package:flutter/material.dart';

// Definizione del tema chiaro
final ThemeData lightTheme = ThemeData(
  primaryColor: Colors.blue,
  hintColor: Color(0xFF1ED660),

);

// Definizione del tema scuro
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black,
  primaryColor: Colors.black, // Imposta il colore predefinito su nero

  // Imposta il colore del cursore di testo su verde
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: Color(0xFF1ED660),
    selectionHandleColor: Color(0xFF1ED660),
  ),

  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: MaterialStateProperty.all<Color>(Color(0xFF1ED660)), // Imposta il colore del testo del TextButton su verde
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    // Imposta il colore del bordo quando attivo su verde
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF1ED660)),
      borderRadius: BorderRadius.circular(10),
    ),
    labelStyle: TextStyle(color: Colors.white),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF1ED660)),
      // Imposta il colore del testo del pulsante su bianco
      foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
    ),
  ),

    // Imposta il colore della barra di navigazione su grigio
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.black,
  ),

  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.grey[800],
    selectedItemColor: Color(0xFF1ED660),
    unselectedItemColor: Colors.grey,
  ),

  dialogTheme: DialogTheme(
    backgroundColor: Colors.grey[800], // Imposta lo sfondo del dialogo su grigio scuro
  ),

  // Applica il filtro di colore verde alle immagini di default
  colorScheme: ColorScheme.dark().copyWith(
    primary: Color(0xFF1ED660),
  ),


);

// Definizione di colori personalizzati
class AppColors {
  static const Color primaryColor = Colors.blue;
  static const Color accentColor = Colors.green;
// Altri colori personalizzati...
}

// Definizione di stili di testo personalizzati
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  static const TextStyle body = TextStyle(fontSize: 16);

}

// Definizione di padding e margini personalizzati
class AppSpacing {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

}
