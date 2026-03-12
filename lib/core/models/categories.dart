class Categories {
  final int? id;
  final String name;
  final String icon;
  final String colorHex;
  final String type;
  final bool isDefault;

  Categories(
      {this.id,
      required this.name,
      required this.icon,
      required this.colorHex,
      required this.type,
      this.isDefault = false});

  factory Categories.fromMap(Map<String, dynamic> map) {
    return Categories(
        id: map['id'],
        name: map['name'],
        icon: map['icon'],
        colorHex: map['color_hex'],
        type: map['type'],
        isDefault: map['is_default'] == 1);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'color_hex': colorHex,
      'type': type,
      'is_default': isDefault ? 1 : 0
    };
  }
}
