import 'package:flutter/material.dart'; //°
import 'encyclopedia_screen.dart'; //° pantalla 5 (explorar el mapa/enciclopedia)
import 'mis_creaciones_screen.dart'; //° pantalla de tu compañero
import 'collection_screen.dart'; //° pantalla 10 (coleccion)

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0; //_ guarda la pestaña activa

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
      const EncyclopediaScreen(), //! index 0: explorar (enciclopedia completa)
      const MisCreacionesScreen(), //! index 1: crear (la pantalla de tu compañero)
      const CollectionScreen(), //! index 2: coleccion (capturados)
    ];

    return Scaffold(
      body: pages[_selectedIndex], //_ muestra la pantalla correspondiente
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _selectPage,
        selectedItemColor: Theme.of(context).colorScheme.primary, //_ usa el color del theme de tu compañero
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'explorar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'crear',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'coleccion',
          ),
        ],
        
      ),
    );
  }
}