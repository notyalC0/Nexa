import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nexa/core/config/app_config.dart';
import 'package:nexa/core/database/database_helper.dart';
import 'package:nexa/core/models/category_goal.dart';
import 'package:nexa/core/models/categories.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/core/utils/currency_formatter.dart';
import 'package:nexa/core/utils/input_masks.dart';
import 'package:nexa/features/goals/providers/goals_provider.dart';
import 'package:nexa/features/insights/providers/analytics_provider.dart';
import 'package:nexa/features/settings/widgets/settings_widget.dart';
import 'package:nexa/features/transactions/providers/transactions_provider.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  Color _hexToColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppTheme.primaryColor;
    }
  }

  IconData _categoryIcon(String name) {
    const map = <String, IconData>{
      'restaurant': Icons.restaurant_rounded,
      'directions_car': Icons.directions_car_rounded,
      'sports_esports': Icons.sports_esports_rounded,
      'health_and_safety': Icons.health_and_safety_rounded,
      'label_outline': Icons.label_outline_rounded,
      'label': Icons.label_outline_rounded,
      'payments': Icons.payments_rounded,
      'work': Icons.work_rounded,
      'shopping_cart': Icons.shopping_cart_rounded,
      'home': Icons.home_rounded,
      'flight': Icons.flight_rounded,
      'school': Icons.school_rounded,
      'attach_money': Icons.attach_money_rounded,
      'savings': Icons.savings_rounded,
      'fitness_center': Icons.fitness_center_rounded,
      'local_gas_station': Icons.local_gas_station_rounded,
      'movie': Icons.movie_rounded,
      'music_note': Icons.music_note_rounded,
      'pets': Icons.pets_rounded,
      'phone': Icons.phone_rounded,
      'computer': Icons.computer_rounded,
      'wifi': Icons.wifi_rounded,
      'bolt': Icons.bolt_rounded,
      'water_drop': Icons.water_drop_rounded,
      'trending_up': Icons.trending_up_rounded,
      'category': Icons.category_rounded,
    };
    return map[name] ?? Icons.category_rounded;
  }

  Future<void> _showAddCategorySheet() async {
    final cs = Theme.of(context).colorScheme;
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppTheme.paddingScreen,
          right: AppTheme.paddingScreen,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adicionar categoria',
                style: AppTheme.titleStyle(context, fontSize: 18),
              ),
              const Gap(6),
              Text(
                'Crie uma categoria personalizada para organizar melhor seus gastos.',
                style: AppTheme.subtitleStyle(
                  context,
                  fontSize: 13,
                  color: cs.onSurface.withAlpha(140),
                ),
              ),
              const Gap(20),
              TextFormField(
                controller: controller,
                autofocus: true,
                style: AppTheme.inputTextStyle(context),
                cursorColor: cs.primary,
                decoration: AppTheme.inputDecoration(
                  context,
                  label: 'Nome da categoria',
                  icon: Icons.category_rounded,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome da categoria';
                  }
                  if (value.trim().length < 2) {
                    return 'Nome muito curto (mín. 2 caracteres)';
                  }
                  return null;
                },
              ),
              const Gap(24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                    ),
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final name = controller.text.trim();
                    final existing =
                        await DatabaseHelper.instance.getCategories();
                    final alreadyExists = existing.any(
                      (category) =>
                          category.name.toLowerCase() == name.toLowerCase(),
                    );

                    if (alreadyExists) {
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        AppTheme.snackBar(
                          context,
                          message: 'A categoria "$name" já existe.',
                        ),
                      );
                      return;
                    }

                    await DatabaseHelper.instance.insertCategory(
                      Categories(
                        name: name,
                        icon: 'label_outline',
                        colorHex: '#5B5F97',
                        type: 'expense',
                      ),
                    );

                    ref.invalidate(categoriesProvider);
                    ref.invalidate(analyticsProvider);

                    if (!mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      AppTheme.snackBar(
                        context,
                        message: 'Categoria "$name" adicionada com sucesso!',
                        icon: Icons.check_circle_outline_rounded,
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF133223)
                                : const Color(0xFF166534),
                        foregroundColor: Colors.white,
                      ),
                    );
                  },
                  child: const Text('Adicionar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCategoryActions(
    Categories category,
    CategoryGoal? goal,
  ) async {
    final cs = Theme.of(context).colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  ),
                  child: Icon(Icons.edit_rounded, color: cs.primary, size: 18),
                ),
                title: Text(
                  'Editar nome',
                  style: AppTheme.actionStyle(context, fontSize: 14),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditNameSheet(category);
                },
              ),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  ),
                  child: Icon(
                    Icons.track_changes_rounded,
                    color: cs.primary,
                    size: 18,
                  ),
                ),
                title: Text(
                  'Definir meta de gasto',
                  style: AppTheme.actionStyle(context, fontSize: 14),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showGoalSheet(category, existingGoal: goal);
                },
              ),
              if (goal != null)
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withAlpha(20),
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                    ),
                    child: const Icon(
                      Icons.remove_circle_outline_rounded,
                      color: Colors.orangeAccent,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    'Remover meta',
                    style: AppTheme.actionStyle(context, fontSize: 14),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await DatabaseHelper.instance
                        .deleteCategoryGoal(category.id!);
                    ref.invalidate(categoryGoalsProvider);
                    ref.invalidate(analyticsProvider);
                  },
                ),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: cs.error,
                    size: 18,
                  ),
                ),
                title: Text(
                  'Excluir categoria',
                  style: AppTheme.actionStyle(
                    context,
                    fontSize: 14,
                    color: cs.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteCategory(category);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditNameSheet(Categories category) async {
    final cs = Theme.of(context).colorScheme;
    final controller = TextEditingController(text: category.name);
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppTheme.paddingScreen,
          right: AppTheme.paddingScreen,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editar categoria',
                style: AppTheme.titleStyle(context, fontSize: 18),
              ),
              const Gap(6),
              Text(
                'Renomeie a categoria sem perder o histórico das transações.',
                style: AppTheme.subtitleStyle(
                  context,
                  fontSize: 13,
                  color: cs.onSurface.withAlpha(140),
                ),
              ),
              const Gap(20),
              TextFormField(
                controller: controller,
                autofocus: true,
                style: AppTheme.inputTextStyle(context),
                cursorColor: cs.primary,
                decoration: AppTheme.inputDecoration(
                  context,
                  label: 'Nome da categoria',
                  icon: Icons.edit_rounded,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome da categoria';
                  }
                  if (value.trim().length < 2) {
                    return 'Nome muito curto (mín. 2 caracteres)';
                  }
                  return null;
                },
              ),
              const Gap(24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                    ),
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final updated = Categories(
                      id: category.id,
                      name: controller.text.trim(),
                      icon: category.icon,
                      colorHex: category.colorHex,
                      type: category.type,
                      isDefault: category.isDefault,
                    );

                    await DatabaseHelper.instance.updateCategory(updated);

                    // Também invalidamos analytics porque os nomes das categorias
                    // aparecem diretamente na aba de análise.
                    ref.invalidate(categoriesProvider);
                    ref.invalidate(analyticsProvider);

                    if (mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showGoalSheet(
    Categories category, {
    CategoryGoal? existingGoal,
  }) async {
    final cs = Theme.of(context).colorScheme;
    final controller = TextEditingController(
      text: existingGoal == null
          ? ''
          : InputMasks.centsToCurrencyText(existingGoal.limitCents),
    );
    final formKey = GlobalKey<FormState>();
    final mask = InputMasks.currency();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppTheme.paddingScreen,
          right: AppTheme.paddingScreen,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meta de gasto',
                style: AppTheme.titleStyle(context, fontSize: 18),
              ),
              const Gap(6),
              Text(
                'Defina um limite mensal para acompanhar excessos com mais clareza.',
                style: AppTheme.subtitleStyle(
                  context,
                  fontSize: 13,
                  color: cs.onSurface.withAlpha(140),
                ),
              ),
              const Gap(20),
              TextFormField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[mask],
                style: AppTheme.inputTextStyle(context),
                cursorColor: cs.primary,
                decoration: AppTheme.inputDecoration(
                  context,
                  label: 'Limite mensal',
                  icon: Icons.track_changes_rounded,
                  prefixText: 'R\$ ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o limite da meta';
                  }
                  if (InputMasks.currencyToCents(value) <= 0) {
                    return 'O limite deve ser maior que zero';
                  }
                  return null;
                },
              ),
              const Gap(24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                    ),
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final goalCount =
                        await DatabaseHelper.instance.getCategoryGoalCount();
                    final isNewGoal = existingGoal == null;

                    if (!AppConfig.isPremium &&
                        goalCount >= AppConfig.freeGoalsLimit &&
                        isNewGoal) {
                      if (!mounted) return;
                      await showDialog<void>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(
                            'Limite do plano gratuito',
                            style: AppTheme.titleStyle(context, fontSize: 16),
                          ),
                          content: Text(
                            'Você atingiu o limite de 3 metas do plano gratuito.',
                            style:
                                AppTheme.subtitleStyle(context, fontSize: 14),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Entendi'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    await DatabaseHelper.instance.upsertCategoryGoal(
                      CategoryGoal(
                        id: existingGoal?.id,
                        categoryId: category.id!,
                        limitCents: InputMasks.currencyToCents(controller.text),
                      ),
                    );

                    ref.invalidate(categoryGoalsProvider);
                    ref.invalidate(analyticsProvider);

                    if (mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteCategory(Categories category) async {
    final cs = Theme.of(context).colorScheme;

    if (category.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.snackBar(
          context,
          message: 'Categorias padrão não podem ser removidas',
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Excluir categoria',
          style: AppTheme.titleStyle(context, fontSize: 16),
        ),
        content: Text(
          'As transações desta categoria serão movidas para "Sem categoria". Deseja continuar?',
          style: AppTheme.subtitleStyle(
            context,
            fontSize: 14,
            color: cs.onSurface.withAlpha(170),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DatabaseHelper.instance.deleteCategory(category.id!);
      ref.invalidate(categoriesProvider);
      ref.invalidate(categoryGoalsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(analyticsProvider);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.snackBar(
          context,
          message: error.toString(),
          icon: Icons.error_outline_rounded,
          backgroundColor: cs.error,
          foregroundColor: Colors.white,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categoriesAsync = ref.watch(categoriesProvider);
    final goalsAsync = ref.watch(categoryGoalsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: Text(
          'Categorias',
          style: AppTheme.titleStyle(context, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _showAddCategorySheet,
              icon: Icon(Icons.add_rounded, size: 18, color: cs.primary),
              label: Text(
                'Adicionar',
                style: AppTheme.actionStyle(
                  context,
                  fontSize: 13,
                  color: cs.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (categories) => goalsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erro: $error')),
          data: (goals) {
            final goalsByCategory = {
              for (final goal in goals) goal.categoryId: goal,
            };

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.paddingScreen,
                8,
                AppTheme.paddingScreen,
                40,
              ),
              children: [
                const SettingsSectionHeader(label: 'Categorias'),
                const Gap(10),
                for (final category in categories) ...[
                  _CategoryTile(
                    category: category,
                    goal: goalsByCategory[category.id],
                    color: _hexToColor(category.colorHex),
                    icon: _categoryIcon(category.icon),
                    onMore: () => _showCategoryActions(
                        category, goalsByCategory[category.id]),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Categories category;
  final CategoryGoal? goal;
  final Color color;
  final IconData icon;
  final VoidCallback onMore;

  const _CategoryTile({
    required this.category,
    required this.goal,
    required this.color,
    required this.icon,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingCard,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: cs.onSurface.withAlpha(20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.name,
                        style: AppTheme.actionStyle(
                          context,
                          fontSize: 14,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    if (category.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          'Padrão',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  category.type == 'income' ? 'Receita' : 'Despesa',
                  style: AppTheme.metaStyle(
                    context,
                    fontSize: 12,
                    color: cs.onSurface.withAlpha(127),
                  ),
                ),
                if (goal != null) ...[
                  const Gap(6),
                  Row(
                    children: [
                      Icon(
                        Icons.track_changes_rounded,
                        size: 14,
                        color: cs.primary,
                      ),
                      const Gap(6),
                      Expanded(
                        child: Text(
                          'Meta mensal: ${CurrencyFormatter.format(goal!.limitCents)}',
                          style: AppTheme.metaStyle(
                            context,
                            fontSize: 12,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onMore,
            icon: Icon(
              Icons.more_vert_rounded,
              color: cs.onSurface.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }
}
