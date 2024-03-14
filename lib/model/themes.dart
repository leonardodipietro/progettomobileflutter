import 'package:flutter/material.dart';

// Definizione del tema chiaro
final ThemeData lightTheme = ThemeData(
  primaryColor: Colors.blue,
  hintColor: Colors.green,
  // Altri attributi del tema chiaro...
);

// Definizione del tema scuro
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
    ),
  ),
  // Imposta il colore della barra di navigazione su grigio
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey,
  ),
  // Altri attributi del tema scuro...
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
// Altri stili di testo personalizzati...
}

// Definizione di padding e margini personalizzati
class AppSpacing {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
// Altri padding e margini personalizzati...
}
