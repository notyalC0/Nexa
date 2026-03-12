import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa/core/models/categories.dart';

import '../../../core/database/database_helper.dart';


final categoriesProvider = FutureProvider<List<Categories>>((ref) async {
  return DatabaseHelper.instance.getCategories();
});
