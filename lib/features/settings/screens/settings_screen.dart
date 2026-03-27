import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nexa/core/database/database_helper.dart';
import 'package:nexa/core/models/categories.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/core/utils/currency_formatter.dart';
import 'package:nexa/core/utils/input_masks.dart';
import 'package:nexa/features/cards/providers/cards_provider.dart';
import 'package:nexa/features/home/provider/balance_provider.dart';
import 'package:nexa/features/home/provider/health_score_provider.dart';
import 'package:nexa/features/settings/providers/app_settings_provider.dart';
import 'package:nexa/features/settings/widgets/settings_widget.dart';
import 'package:nexa/features/transactions/providers/transactions_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // ─── Dialogs e Sheets ────────────────────────────────────────────────────

  void _showAboutDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusModal)),
        backgroundColor: cs.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.account_balance_wallet_rounded,
                  color: cs.onPrimary, size: 32),
            ),
            const Gap(16),
            Text('Nexa',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface)),
            const Gap(4),
            Text('Versão 1.0.0',
                style: TextStyle(
                    fontSize: 13, color: cs.onSurface.withAlpha(127))),
            const Gap(12),
            Text(
              'Controle financeiro pessoal simples e eficiente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withAlpha(166),
                  height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Fechar',
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: cs.primary)),
          ),
        ],
      ),
    );
  }

  /// Sheet para inserir valores monetários (salário, reserva, etc.)
  ///
  /// CORREÇÃO: agora usa Form + validator, então não salva valor zero
  /// por acidente se o usuário não preencher nada.
  void _showFinancialSheet(
    BuildContext context,
    WidgetRef ref,
    String key,
    String title,
  ) {
    final cs = Theme.of(context).colorScheme;
    final controller = TextEditingController();
    final currencyMask = InputMasks.currency();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusModal)),
      ),
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
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withAlpha(38),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface),
              ),
              const Gap(16),
              TextFormField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [currencyMask],
                autofocus: true,
                decoration: InputDecoration(
                  prefixText: 'R\$ ',
                  labelText: 'Valor',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withAlpha(102),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                    borderSide: BorderSide(color: cs.onSurface.withAlpha(51)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                    borderSide: BorderSide(color: cs.primary, width: 1.8),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                    borderSide: BorderSide(color: cs.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                    borderSide: BorderSide(color: cs.error, width: 1.8),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe um valor';
                  if (InputMasks.currencyToCents(v) <= 0) {
                    return 'O valor deve ser maior que zero';
                  }
                  return null;
                },
              ),
              const Gap(16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusChip)),
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final cents = InputMasks.currencyToCents(controller.text);
                    await ref
                        .read(appSettingsProvider.notifier)
                        .saveMoneySetting(key, cents);
                    ref.invalidate(healthScoreProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Salvar',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dialog para adicionar nova categoria personalizada.
  ///
  /// CORREÇÃO: trim() no nome para evitar categorias " " (espaço em branco).
  Future<void> _showManageCategoriesDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final cs = Theme.of(context).colorScheme;
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusModal)),
        backgroundColor: cs.surface,
        title: Text('Nova categoria',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome da categoria'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Informe o nome da categoria';
              }
              if (v.trim().length < 2) {
                return 'Nome muito curto (mín. 2 caracteres)';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              elevation: 0,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final name = controller.text.trim();
              final existing = await DatabaseHelper.instance.getCategories();

              // Verifica duplicata (case-insensitive)
              final alreadyExists = existing.any(
                (c) => c.name.toLowerCase() == name.toLowerCase(),
              );

              if (alreadyExists) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('A categoria "$name" já existe.')),
                  );
                }
                return;
              }

              await DatabaseHelper.instance.insertCategory(
                Categories(
                  name: name,
                  icon: 'label',
                  colorHex: '#5B5F97',
                  type: 'expense',
                ),
              );

              ref.invalidate(categoriesProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Categoria "$name" adicionada com sucesso!')),
                );
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _showClearDataConfirm(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusModal)),
        backgroundColor: cs.surface,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.error.withAlpha(25),
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            ),
            child: Icon(Icons.warning_amber_rounded, color: cs.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Apagar dados',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
          ),
        ]),
        content: Text(
          'Todos os dados serão removidos permanentemente. Esta ação não pode ser desfeita.',
          style: TextStyle(
              fontSize: 14, color: cs.onSurface.withAlpha(178), height: 1.4),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
                foregroundColor: cs.onSurface.withAlpha(153)),
            child: const Text('Cancelar',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.clearAllData();
              // Invalida todos os providers para resetar o estado da UI
              ref
                ..invalidate(categoriesProvider)
                ..invalidate(transactionsProvider)
                ..invalidate(transactionsByMonthProvider)
                ..invalidate(creditCardProvider)
                ..invalidate(balanceProvider)
                ..invalidate(healthScoreProvider)
                ..invalidate(appSettingsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip)),
            ),
            child: const Text('Apagar tudo',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final settingsAsync = ref.watch(appSettingsProvider);

    return settingsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erro: $e'))),
      data: (settings) => Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          centerTitle: false,
          title: Text(
            'Configurações',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.paddingScreen, 8, AppTheme.paddingScreen, 40),
          children: [
            // ── Perfil ──────────────────────────────────────────────
            _ProfileCard(cs: cs),
            const Gap(24),

            // ── Finanças ────────────────────────────────────────────
            const SettingsSectionHeader(label: 'Finanças'),
            const Gap(10),
            SettingsTile(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Salário mensal',
              subtitle: settings.salaryCents == 0
                  ? 'Não configurado'
                  : CurrencyFormatter.format(settings.salaryCents),
              trailing: Icon(Icons.chevron_right_rounded,
                  color: cs.onSurface.withAlpha(89)),
              onTap: () => _showFinancialSheet(
                  context, ref, 'monthly_salary_cents', 'Salário mensal'),
            ),
            SettingsTile(
              icon: Icons.savings_rounded,
              title: 'Meta da reserva de emergência',
              subtitle: settings.emergencyGoalCents == 0
                  ? 'Não configurado'
                  : CurrencyFormatter.format(settings.emergencyGoalCents),
              trailing: Icon(Icons.chevron_right_rounded,
                  color: cs.onSurface.withAlpha(89)),
              onTap: () => _showFinancialSheet(
                  context, ref, 'emergency_goal_cents', 'Meta da reserva'),
            ),
            SettingsTile(
              icon: Icons.savings_outlined,
              title: 'Reserva atual',
              subtitle: settings.emergencyCurrentCents == 0
                  ? 'Não configurado'
                  : CurrencyFormatter.format(settings.emergencyCurrentCents),
              trailing: Icon(Icons.chevron_right_rounded,
                  color: cs.onSurface.withAlpha(89)),
              onTap: () => _showFinancialSheet(
                  context, ref, 'emergency_current_cents', 'Reserva atual'),
            ),
            const Gap(24),

            // ── Aparência ────────────────────────────────────────────
            const SettingsSectionHeader(label: 'Aparência'),
            const Gap(10),
            SettingsTile(
              icon: Icons.dark_mode_rounded,
              title: 'Modo escuro',
              subtitle: 'Ativar tema escuro no app',
              trailing: Switch(
                value: settings.darkMode,
                onChanged: (v) => ref
                    .read(appSettingsProvider.notifier)
                    .saveBoolSetting('dark_mode', v),
                activeThumbColor: cs.primary,
              ),
            ),
            const Gap(24),

            // ── Notificações ─────────────────────────────────────────
            const SettingsSectionHeader(label: 'Notificações'),
            const Gap(10),
            SettingsTile(
              icon: Icons.notifications_rounded,
              title: 'Notificações',
              subtitle: 'Alertas de transações e vencimentos',
              trailing: Switch(
                value: settings.notificationsEnabled,
                onChanged: (v) => ref
                    .read(appSettingsProvider.notifier)
                    .saveBoolSetting('notifications_enabled', v),
                activeThumbColor: cs.primary,
              ),
            ),
            const Gap(24),

            // ── Categorias ────────────────────────────────────────────
            const SettingsSectionHeader(label: 'Categorias'),
            const Gap(10),
            SettingsTile(
              icon: Icons.category_rounded,
              title: 'Adicionar categoria',
              subtitle: 'Crie categorias personalizadas para transações',
              trailing: Icon(Icons.chevron_right_rounded,
                  color: cs.onSurface.withAlpha(89)),
              onTap: () => _showManageCategoriesDialog(context, ref),
            ),
            const Gap(24),

            // ── Dados ─────────────────────────────────────────────────
            const SettingsSectionHeader(label: 'Dados'),
            const Gap(10),
            SettingsTile(
              icon: Icons.delete_forever_rounded,
              title: 'Apagar todos os dados',
              subtitle: 'Remove todas as transações e cartões',
              iconColor: cs.error,
              titleColor: cs.error,
              trailing: Icon(Icons.chevron_right_rounded,
                  color: cs.error.withAlpha(127)),
              onTap: () => _showClearDataConfirm(context, ref),
            ),
            const Gap(24),

            // ── Sobre ──────────────────────────────────────────────────
            const SettingsSectionHeader(label: 'Sobre'),
            const Gap(10),
            SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'Sobre o Nexa',
              subtitle: 'Versão 1.0.0',
              trailing: Icon(Icons.chevron_right_rounded,
                  color: cs.onSurface.withAlpha(89)),
              onTap: () => _showAboutDialog(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets internos ────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final ColorScheme cs;

  const _ProfileCard({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingCard),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cs.onPrimary.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_rounded, color: cs.onPrimary, size: 26),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Usuário',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimary)),
                Text('Conta pessoal',
                    style: TextStyle(
                        fontSize: 13, color: cs.onPrimary.withAlpha(166))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
