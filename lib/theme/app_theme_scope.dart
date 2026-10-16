import 'package:flutter/material.dart';

// Comparte la selección de tema sin guardarla fuera de la aplicación.
class AppThemeScope extends InheritedWidget {
  final bool modoOscuro;
  final ValueChanged<bool> cambiarModoOscuro;

  const AppThemeScope({
    super.key,
    required this.modoOscuro,
    required this.cambiarModoOscuro,
    required super.child,
  });

  static AppThemeScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppThemeScope>()!;

  @override
  bool updateShouldNotify(AppThemeScope oldWidget) =>
      modoOscuro != oldWidget.modoOscuro;
}
