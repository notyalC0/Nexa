import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nexa/core/database/database_helper.dart';
import 'package:nexa/core/models/categories.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/core/utils/currency_formatter.dart';
import 'package:nexa/features/cards/providers/cards_provider.dart';
import 'package:nexa/features/home/provider/balance_provider.dart';
import 'package:nexa/features/home/provider/health_score_provider.dart';
import 'package:nexa/features/settings/providers/app_settings_provider.dart';
import 'package:nexa/features/transactions/providers/transactions_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showAboutDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusModal)),
        backgroundColor: colorScheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.account_balance_wallet_rounded,
                  color: colorScheme.onPrimary, size: 32),
            ),
            const Gap(16),
            Text('Nexa',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface)),
            const Gap(4),
            Text('Versão 1.0.0',
                style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.5))),
            const Gap(12),
            Text('Controle financeiro pessoal simples e eficiente.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.65),
                    height: 1.4)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Fechar',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showFinancialSheet(
    BuildContext context,
    WidgetRef ref,
    String key,
    String title,
  ) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppTheme.paddingScreen,
          right: AppTheme.paddingScreen,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            const Gap(16),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: 'R\$ ',
                labelText: 'Valor',
              ),
            ),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final value =
                      double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
                  final cents = (value * 100).toInt();
                  await ref
                      .read(appSettingsProvider.notifier)
                      .saveMoneySetting(key, cents);

                  ref.invalidate(healthScoreProvider);
                  if (context.mounted) Navigator.pop(ctx);
                },
                child: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showManageCategoriesDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusModal)),
        backgroundColor: colorScheme.surface,
        title: const Text('Nova categoria'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          decoration:
              const InputDecoration(labelText: 'Nome da categoria'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              final existingCategories =
                  await DatabaseHelper.instance.getCategories();
              final alreadyExists = existingCategories.any(
                (category) => category.name.toLowerCase() == name.toLowerCase(),
              );

              if (alreadyExists) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Essa categoria já existe.'),
                    ),
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
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Categoria "$name" adicionada com sucesso!'),
                  ),
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
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusModal)),
        backgroundColor: colorScheme.surface,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusChip)),
            child: Icon(Icons.warning_amber_rounded,
                color: colorScheme.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text('Apagar dados',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface))),
        ]),
        content: Text(
            'Todos os dados serão removidos permanentemente. Esta ação não pode ser desfeita.',
            style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.7),
                height: 1.4)),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurface.withOpacity(0.6)),
            child: const Text('Cancelar',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.clearAllData();
              ref.invalidate(transactionsProvider);
              ref.invalidate(creditCardProvider);
              ref.invalidate(balanceProvider);
              ref.invalidate(healthScoreProvider);
              ref.invalidate(appSettingsProvider);
              if (context.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsAsync = ref.watch(appSettingsProvider);

    return settingsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erro: $e'))),
      data: (settings) => Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          centerTitle: false,
          title: Text('Configurações',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.paddingScreen, 8, AppTheme.paddingScreen, 40),
          children: [
            _buildProfileCard(colorScheme),
            const Gap(24),
            _SectionHeader(label: 'Finanças'),
            const Gap(10),
            _SettingsTile(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Salário mensal',
              subtitle: settings.salaryCents == 0
                  ? 'Não configurado'
                  : CurrencyFormatter.format(settings.salaryCents),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showFinancialSheet(
                  context, ref, 'monthly_salary_cents', 'Salário mensal'),
            ),
            _SettingsTile(
              icon: Icons.savings_rounded,
              title: 'Meta da reserva',
              subtitle: settings.emergencyGoalCents == 0
                  ? 'Não configurado'
                  : CurrencyFormatter.format(settings.emergencyGoalCents),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showFinancialSheet(
                  context, ref, 'emergency_goal_cents', 'Meta da reserva'),
            ),
            _SettingsTile(
              icon: Icons.savings_rounded,
              title: 'Reserva atual',
              subtitle: settings.emergencyCurrentCents == 0
                  ? 'Não configurado'
                  : CurrencyFormatter.format(settings.emergencyCurrentCents),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showFinancialSheet(
                  context, ref, 'emergency_current_cents', 'Reserva atual'),
            ),
            const Gap(24),
            _SectionHeader(label: 'Aparência'),
            const Gap(10),
            _SettingsTile(
              icon: Icons.dark_mode_rounded,
              title: 'Modo escuro',
              subtitle: 'Ativar tema escuro',
              trailing: Switch(
                value: settings.darkMode,
                onChanged: (v) => ref
                    .read(appSettingsProvider.notifier)
                    .saveBoolSetting('dark_mode', v),
                activeThumbColor: colorScheme.primary,
              ),
            ),
            _SettingsTile(
              icon: Icons.visibility_off_rounded,
              title: 'Ocultar saldo',
              subtitle: 'Esconder valores na tela inicial',
              trailing: Switch(
                value: settings.hideBalance,
                onChanged: (v) => ref
                    .read(appSettingsProvider.notifier)
                    .saveBoolSetting('hide_balance', v),
                activeThumbColor: colorScheme.primary,
              ),
            ),
            const Gap(24),
            _SectionHeader(label: 'Notificações'),
            const Gap(10),
            _SettingsTile(
              icon: Icons.notifications_rounded,
              title: 'Notificações',
              subtitle: 'Alertas de transações e vencimentos',
              trailing: Switch(
                value: settings.notificationsEnabled,
                onChanged: (v) => ref
                    .read(appSettingsProvider.notifier)
                    .saveBoolSetting('notifications_enabled', v),
                activeThumbColor: colorScheme.primary,
              ),
            ),
            const Gap(24),
            _SectionHeader(label: 'Gerenciar Categorias'),
            const Gap(10),
            _SettingsTile(
              icon: Icons.category_rounded,
              title: 'Adicionar categoria',
              subtitle: 'Crie categorias personalizadas para transações',
              trailing: Icon(Icons.chevron_right_rounded,
                  color: colorScheme.onSurface.withOpacity(0.35)),
              onTap: () => _showManageCategoriesDialog(context, ref),
            ),
            const Gap(24),
            _SectionHeader(label: 'Dados'),
            const Gap(10),
            _SettingsTile(
              icon: Icons.delete_forever_rounded,
              title: 'Apagar todos os dados',
              subtitle: 'Remove todas as transações e cartões',
              iconColor: colorScheme.error,
              titleColor: colorScheme.error,
              trailing: Icon(Icons.chevron_right_rounded,
                  color: colorScheme.error.withOpacity(0.5)),
              onTap: () => _showClearDataConfirm(context, ref),
            ),
            const Gap(24),
            _SectionHeader(label: 'Sobre'),
            const Gap(10),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'Sobre o Nexa',
              subtitle: 'Versão 1.0.0',
              trailing: Icon(Icons.chevron_right_rounded,
                  color: colorScheme.onSurface.withOpacity(0.35)),
              onTap: () => _showAboutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingCard),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.onPrimary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_rounded,
                color: colorScheme.onPrimary, size: 26),
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
                        color: colorScheme.onPrimary)),
                Text('Conta pessoal',
                    style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onPrimary.withOpacity(0.65))),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45)));
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingCard, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (iconColor ?? colorScheme.primary).withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
              child:
                  Icon(icon, size: 18, color: iconColor ?? colorScheme.primary),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: titleColor ?? colorScheme.onSurface)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
