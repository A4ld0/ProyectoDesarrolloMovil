import '../models/creature.dart';

//_ lista hardcodeada de criaturas inventadas para probar la interfaz
const List<Creature> dummyCreatures = [
  Creature(
    id: 'c1',
    name: 'zorvex',
    imageUrl: 'https://img.freepik.com/vector-gratis/lindo-monstruo-dibujos-animados-aislado_1308-134903.jpg', 
    description: 'es jugueton pero muy leal. ama los lugares con mucha energia.',
    types: ['dragon', 'electrico'],
    hp: 78,
    attack: 64,
    defense: 61,
    speed: 72,
    isCaptured: true, //! saldra a color en tu coleccion
  ),
  Creature(
    id: 'c2',
    name: 'flamito',
    imageUrl: 'https://img.freepik.com/vector-gratis/lindo-monstruo-dibujos-animados-aislado_1308-134909.jpg',
    description: 'pequeña llama que nunca se apaga.',
    types: ['fuego'],
    hp: 45,
    attack: 55,
    defense: 40,
    speed: 60,
    isCaptured: false, //! saldra gris en la enciclopedia
  ),
  Creature(
    id: 'c3',
    name: 'acuadin',
    imageUrl: 'https://img.freepik.com/vector-gratis/lindo-monstruo-dibujos-animados-aislado_1308-134905.jpg',
    description: 'le encanta nadar en charcos despues de la lluvia.',
    types: ['agua'],
    hp: 60,
    attack: 50,
    defense: 65,
    speed: 45,
    isCaptured: true,
  ),
];