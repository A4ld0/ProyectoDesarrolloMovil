import 'package:flutter/material.dart'; //°

import 'encyclopedia_screen.dart'; //° pantalla 5 (explorar el mapa/enciclopedia)
import 'mis_creaciones_screen.dart'; //° pantalla de tu compañero
import 'collection_screen.dart'; //° pantalla 10 (coleccion)
import 'mapa_screen.dart';
import 'ajustes_screen.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0; //_ guarda la pestaña activa

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  //* cambia la vista segun la pestaña tocada
  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    //_ ordenamos las pestañas exactamente como en el mockup de referencia
    final List<Widget> pages = [
      const MapaScreen(), //! index 0: mapa y captura
      const EncyclopediaScreen(), //! index 1: enciclopedia completa
      const MisCreacionesScreen(), //! index 2: crear criaturas
      const CollectionScreen(), //! index 3: coleccion de capturados
      const AjustesScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex], //_ muestra la pantalla correspondiente
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        onTap: _selectPage,
        selectedItemColor: Theme.of(context)
            .colorScheme
            .primary, //_ usa el color del theme de tu compañero
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Enciclopedia',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Mis creaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Colección',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
