import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:nexa/core/database/database_helper.dart';
import 'package:nexa/core/models/goals.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/core/utils/currency_formatter.dart';
import 'package:nexa/core/utils/input_masks.dart';
import 'package:nexa/core/widgets/app_empty_state.dart';
import 'package:nexa/features/goals/models/goal_progress.dart';
import 'package:nexa/features/goals/providers/goals_provider.dart';
import 'package:nexa/features/home/provider/health_score_provider.dart';
import 'package:nexa/features/insights/providers/analytics_provider.dart';
import 'package:nexa/features/transactions/screens/add_transactions_screen.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  void _invalidateAll(WidgetRef ref) {
    ref
      ..invalidate(goalsProvider)
      ..invalidate(defaultGoalProgressProvider)
      ..invalidate(analyticsProvider)
      ..invalidate(healthScoreProvider);
  }

  Future<void> _openGoalSheet(
    BuildContext context,
    WidgetRef ref, {
    Goal? goal,
  }) async {
    final cs = Theme.of(context).colorScheme;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: goal?.name ?? '');
    final targetController = TextEditingController(
      text: goal == null || goal.targetAmountCents == 0
          ? ''
          : InputMasks.centsToCurrencyText(goal.targetAmountCents),
    );
    final currencyMask = InputMasks.currency();
    String icon = goal?.icon ?? 'flag';
    String colorHex = goal?.colorHex ?? '#4D96FF';
    DateTime? targetDate =
        goal?.targetDate == null ? null : DateTime.tryParse(goal!.targetDate!);

    const iconChoices = [
      ('shield', Icons.shield_rounded),
      ('flag', Icons.flag_rounded),
      ('home', Icons.home_rounded),
      ('flight', Icons.flight_rounded),
      ('directions_car', Icons.directions_car_rounded),
      ('school', Icons.school_rounded),
      ('favorite', Icons.favorite_rounded),
      ('payments', Icons.payments_rounded),
    ];
    const colorChoices = [
      '#4D96FF',
      '#2ECC71',
      '#FF6B6B',
      '#F39C12',
      '#9B59B6',
      '#16A085',
      '#E67E22',
      '#34495E',
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: cs.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusModal),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.paddingScreen,
                12,
                AppTheme.paddingScreen,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        goal == null ? 'Nova meta' : 'Editar meta',
                        style: AppTheme.titleStyle(context, fontSize: 18),
                      ),
                      const Gap(8),
                      Text(
                        'Defina alvo, prazo e identidade visual da meta.',
                        style: AppTheme.subtitleStyle(
                          context,
                          fontSize: 13,
                          color: cs.onSurface.withAlpha(150),
                        ),
                      ),
                      const Gap(16),
                      TextFormField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.sentences,
                        style: AppTheme.inputTextStyle(context),
                        decoration: AppTheme.inputDecoration(
                          context,
                          label: 'Nome da meta',
                          icon: Icons.flag_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe um nome';
                          }
                          return null;
                        },
                      ),
                      const Gap(14),
                      TextFormField(
                        controller: targetController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [currencyMask],
                        style: AppTheme.inputTextStyle(context),
                        decoration: AppTheme.inputDecoration(
                          context,
                          label: 'Valor alvo',
                          prefixText: 'R\$ ',
                          icon: Icons.savings_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe o valor alvo';
                          }
                          if (InputMasks.currencyToCents(value) <= 0) {
                            return 'O valor deve ser maior que zero';
                          }
                          return null;
                        },
                      ),
                      const Gap(14),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: targetDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked == null) return;
                          setSheetState(() => targetDate = picked);
                        },
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusCard),
                        child: InputDecorator(
                          decoration: AppTheme.inputDecoration(
                            context,
                            label: 'Prazo (opcional)',
                            icon: Icons.event_rounded,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                targetDate == null
                                    ? 'Sem prazo definido'
                                    : DateFormat('dd/MM/yyyy')
                                        .format(targetDate!),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (targetDate != null)
                                IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: cs.onSurface.withAlpha(140),
                                  ),
                                  onPressed: () =>
                                      setSheetState(() => targetDate = null),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const Gap(18),
                      Text(
                        'Ícone',
                        style: AppTheme.actionStyle(context, fontSize: 14),
                      ),
                      const Gap(10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: iconChoices.map((entry) {
                          final selected = icon == entry.$1;
                          return GestureDetector(
                            onTap: () => setSheetState(() => icon = entry.$1),
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: _hexColor(colorHex)
                                    .withAlpha(selected ? 38 : 18),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusChip),
                                border: Border.all(
                                  color: selected
                                      ? _hexColor(colorHex)
                                      : cs.onSurface.withAlpha(25),
                                ),
                              ),
                              child: Icon(entry.$2, color: _hexColor(colorHex)),
                            ),
                          );
                        }).toList(growable: false),
                      ),
                      const Gap(18),
                      Text(
                        'Cor',
                        style: AppTheme.actionStyle(context, fontSize: 14),
                      ),
                      const Gap(10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: colorChoices.map((choice) {
                          final selected = colorHex == choice;
                          return GestureDetector(
                            onTap: () => setSheetState(() => colorHex = choice),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: _hexColor(choice),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? cs.onSurface
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: selected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(growable: false),
                      ),
                      const Gap(20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusChip),
                            ),
                          ),
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final nowIso = DateTime.now().toIso8601String();
                            final targetAmount = InputMasks.currencyToCents(
                                targetController.text);

                            final savedGoal = Goal(
                              id: goal?.id,
                              name: nameController.text.trim(),
                              targetAmountCents: targetAmount,
                              initialAmountCents: goal?.initialAmountCents ?? 0,
                              targetDate: targetDate == null
                                  ? null
                                  : DateFormat('yyyy-MM-dd')
                                      .format(targetDate!),
                              icon: icon,
                              colorHex: colorHex,
                              isDefault: goal?.isDefault ?? false,
                              isDeletable: goal?.isDeletable ?? true,
                              isArchived: goal?.isArchived ?? false,
                              createdAt: goal?.createdAt ?? nowIso,
                              updatedAt: nowIso,
                            );

                            if (goal == null) {
                              await DatabaseHelper.instance
                                  .insertGoal(savedGoal);
                            } else {
                              await DatabaseHelper.instance
                                  .updateGoal(savedGoal);
                            }

                            _invalidateAll(ref);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Text(goal == null
                              ? 'Criar meta'
                              : 'Salvar alterações'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteGoal(
    BuildContext context,
    WidgetRef ref,
    Goal goal,
  ) async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Excluir meta',
            style: AppTheme.titleStyle(context, fontSize: 16)),
        content: Text(
          'A meta "${goal.name}" será removida. Os aportes vinculados continuarão existindo, mas ficarão sem meta.',
          style: AppTheme.subtitleStyle(context, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await DatabaseHelper.instance.deleteGoal(goal.id!);
    _invalidateAll(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          'Metas',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openGoalSheet(context, ref),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova meta'),
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingScreen),
            child: Text(
              'Não foi possível carregar as metas.',
              style: AppTheme.subtitleStyle(context),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (goals) {
          if (goals.isEmpty) {
            return const AppEmptyState(
              icon: Icons.flag_rounded,
              message: 'Nenhuma meta criada',
              subtitle: 'Crie uma meta para acompanhar objetivos financeiros.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.paddingScreen,
              12,
              AppTheme.paddingScreen,
              100,
            ),
            itemCount: goals.length,
            separatorBuilder: (_, __) => const Gap(12),
            itemBuilder: (context, index) {
              final goal = goals[index];
              return _GoalCard(
                goal: goal,
                onEdit: () => _openGoalSheet(context, ref, goal: goal.goal),
                onDelete: goal.goal.isDeletable
                    ? () => _confirmDeleteGoal(context, ref, goal.goal)
                    : null,
                onContribute: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTransactionsScreen(
                      initialGoalId: goal.goal.id,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalProgress goal;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onContribute;

  const _GoalCard({
    required this.goal,
    required this.onEdit,
    required this.onContribute,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _hexColor(goal.goal.colorHex);
    final pct = goal.progress.clamp(0.0, 1.0);
    final estimateLabel = goal.isReached
        ? 'Meta atingida'
        : goal.estimatedReachDate == null
            ? 'Estimativa: n/a'
            : 'Estimativa: ${DateFormat('MM/yyyy').format(goal.estimatedReachDate!)}';

    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingCard),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: cs.onSurface.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withAlpha(24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_goalIcon(goal.goal.icon), color: color),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            goal.goal.name,
                            style: AppTheme.titleStyle(context, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (goal.goal.isDefault) ...[
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withAlpha(18),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'Padrão',
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Gap(4),
                    Text(
                      'Atual ${CurrencyFormatter.format(goal.currentAmountCents)} de ${CurrencyFormatter.format(goal.goal.targetAmountCents)}',
                      style: AppTheme.metaStyle(context, fontSize: 12),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  if (onDelete != null)
                    const PopupMenuItem(
                        value: 'delete', child: Text('Excluir')),
                ],
              ),
            ],
          ),
          const Gap(16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: cs.onSurface.withAlpha(18),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const Gap(12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Faltam ${CurrencyFormatter.format(goal.remainingCents)}',
                style: AppTheme.metaStyle(context, fontSize: 12),
              ),
              Text(
                '${(goal.progress * 100).round()}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Gap(8),
          Text(
            estimateLabel,
            style: AppTheme.metaStyle(context, fontSize: 12),
          ),
          if (goal.goal.targetDate != null) ...[
            const Gap(4),
            Text(
              'Prazo: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(goal.goal.targetDate!))}',
              style: AppTheme.metaStyle(context, fontSize: 12),
            ),
          ],
          const Gap(14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Editar'),
                ),
              ),
              const Gap(10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onContribute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Aportar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _hexColor(String hex) {
  try {
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  } catch (_) {
    return Colors.grey;
  }
}

IconData _goalIcon(String icon) {
  switch (icon) {
    case 'shield':
      return Icons.shield_rounded;
    case 'home':
      return Icons.home_rounded;
    case 'flight':
      return Icons.flight_rounded;
    case 'directions_car':
      return Icons.directions_car_rounded;
    case 'school':
      return Icons.school_rounded;
    case 'favorite':
      return Icons.favorite_rounded;
    case 'payments':
      return Icons.payments_rounded;
    case 'flag':
    default:
      return Icons.flag_rounded;
  }
}
