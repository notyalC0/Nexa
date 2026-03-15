import 'package:nexa/core/models/categories.dart';

List<Categories> buildDefaultCategories() {
  return [
    Categories(
      name: 'Alimentação',
      icon: 'restaurant',
      colorHex: '#FF6B35',
      type: 'expense',
      isDefault: true,
    ),
    Categories(
      name: 'Transporte',
      icon: 'directions_car',
      colorHex: '#4D96FF',
      type: 'expense',
      isDefault: true,
    ),
    Categories(
      name: 'Lazer',
      icon: 'sports_esports',
      colorHex: '#A66CFF',
      type: 'expense',
      isDefault: true,
    ),
    Categories(
      name: 'Saúde',
      icon: 'health_and_safety',
      colorHex: '#2ECC71',
      type: 'expense',
      isDefault: true,
    ),
  ];
}
