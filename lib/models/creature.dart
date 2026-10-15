//° modelo basico de la criatura (PROTOTIPO)
class Creature {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final List<String> types; //_ array de tipos
  final int hp;
  final int attack;
  final int defense;
  final int speed;
  final bool isCaptured; //! define si ya la descubrio

  const Creature({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.types,
    required this.hp,
    required this.attack,
    required this.defense,
    required this.speed,
    required this.isCaptured,
  });
}