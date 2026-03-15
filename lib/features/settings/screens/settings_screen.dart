import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nexa/core/database/database_helper.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/core/utils/currency_formatter.dart';
import 'package:nexa/features/home/provider/health_score_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _salaryCents = 0;
  int _emergencyGoalCents = 0;
  int _emergencyCurrentCents = 0;
  int _alertThreshold = 75;
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  bool _hideBalance = false;
  String _selectedCurrency = 'BRL';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final salary =
        await DatabaseHelper.instance.getSetting('monthly_salary_cents');
    final goal =
        await DatabaseHelper.instance.getSetting('emergency_goal_cents');
    final current =
        await DatabaseHelper.instance.getSetting('emergency_current_cents');
    final alert =
        await DatabaseHelper.instance.getSetting('health_alert_threshold');

    setState(() {
      _salaryCents = int.tryParse(salary ?? '0') ?? 0;
      _emergencyGoalCents = int.tryParse(goal ?? '0') ?? 0;
      _emergencyCurrentCents = int.tryParse(current ?? '0') ?? 0;
      _alertThreshold = int.tryParse(alert ?? '80') ?? 80;
    });
  }

  void _showAboutDialog() {
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

  void _showFinancialSheet(String key, String title) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
            ),
            const Gap(16),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: 'R\$ ',
                labelText: 'Valor',
              ),
            ),
            const Gap(16),
            ElevatedButton(
              onPressed: () async {
                final value =
                    double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
                final cents = (value * 100).toInt();
                await DatabaseHelper.instance
                    .saveSetting(key, cents.toString());

                Navigator.pop(ctx);
                if (mounted) {
                  await _loadSettings();
                  ref.invalidate(healthScoreProvider); // ← depois de fechar
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDataConfirm() {
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
            onPressed: () {
              // TODO: limpar banco
              Navigator.pop(ctx);
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
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
          // --- Perfil ---
          _buildProfileCard(colorScheme),
          const Gap(24),

          // --- Finanças ---
          _SectionHeader(label: 'Finanças'),
          const Gap(10),
          _SettingsTile(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Salário mensal',
            subtitle: _salaryCents == 0
                ? 'Não configurado'
                : CurrencyFormatter.format(_salaryCents),
            trailing: Icon(
              Icons.chevron_right_rounded,
            ),
            onTap: () =>
                _showFinancialSheet('monthly_salary_cents', 'Salário mensal'),
          ),
          _SettingsTile(
            icon: Icons.savings_rounded,
            title: 'Meta da reserva',
            subtitle: _emergencyGoalCents == 0
                ? 'Não configurado'
                : CurrencyFormatter.format(_emergencyGoalCents),
            trailing: Icon(
              Icons.chevron_right_rounded,
            ),
            onTap: () =>
                _showFinancialSheet('emergency_goal_cents', 'Meta da reserva'),
          ),
          _SettingsTile(
            icon: Icons.savings_rounded,
            title: 'Reserva Atual',
            subtitle: _emergencyCurrentCents == 0
                ? 'Não configurado'
                : CurrencyFormatter.format(_emergencyCurrentCents),
            trailing: Icon(
              Icons.chevron_right_rounded,
            ),
            onTap: () =>
                _showFinancialSheet('emergency_current_cents', 'Reserva atual'),
          ),
          _SettingsTile(
            icon: Icons.savings_rounded,
            title: '% de alerta',
            subtitle: '$_alertThreshold% do salário',
            trailing: Icon(
              Icons.chevron_right_rounded,
            ),
            onTap: () => _showFinancialSheet(
                'health_alert_threshold', 'parametro de alerta'),
          ),
          const Gap(24),

          // --- Aparência ---
          _SectionHeader(label: 'Aparência'),
          const Gap(10),
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            title: 'Modo escuro',
            subtitle: 'Ativar tema escuro',
            trailing: Switch(
              value: _darkMode,
              onChanged: (v) => setState(() => _darkMode = v),
              activeThumbColor: colorScheme.primary,
            ),
          ),
          _SettingsTile(
            icon: Icons.visibility_off_rounded,
            title: 'Ocultar saldo',
            subtitle: 'Esconder valores na tela inicial',
            trailing: Switch(
              value: _hideBalance,
              onChanged: (v) => setState(() => _hideBalance = v),
              activeThumbColor: colorScheme.primary,
            ),
          ),
          const Gap(24),

          // --- Notificações ---
          _SectionHeader(label: 'Notificações'),
          const Gap(10),
          _SettingsTile(
            icon: Icons.notifications_rounded,
            title: 'Notificações',
            subtitle: 'Alertas de transações e vencimentos',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
              activeThumbColor: colorScheme.primary,
            ),
          ),
          const Gap(24),

          // --- Preferências ---
          _SectionHeader(label: 'Preferências'),
          const Gap(10),
          _SettingsTile(
            icon: Icons.attach_money_rounded,
            title: 'Moeda',
            subtitle: _selectedCurrency == 'BRL'
                ? 'Real Brasileiro (R\$)'
                : _selectedCurrency,
            trailing: Icon(Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withOpacity(0.35)),
            onTap: () => _showCurrencyPicker(colorScheme),
          ),
          _SettingsTile(
            icon: Icons.category_rounded,
            title: 'Categorias',
            subtitle: 'Gerenciar categorias de transações',
            trailing: Icon(Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withOpacity(0.35)),
            onTap: () {}, // TODO: navegar para tela de categorias
          ),
          const Gap(24),

          // --- Dados ---
          _SectionHeader(label: 'Dados'),
          const Gap(10),
          _SettingsTile(
            icon: Icons.upload_rounded,
            title: 'Exportar dados',
            subtitle: 'Exportar transações em CSV',
            trailing: Icon(Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withOpacity(0.35)),
            onTap: () {}, // TODO: exportar
          ),
          _SettingsTile(
            icon: Icons.delete_forever_rounded,
            title: 'Apagar todos os dados',
            subtitle: 'Remove todas as transações e cartões',
            iconColor: colorScheme.error,
            titleColor: colorScheme.error,
            trailing: Icon(Icons.chevron_right_rounded,
                color: colorScheme.error.withOpacity(0.5)),
            onTap: _showClearDataConfirm,
          ),
          const Gap(24),

          // --- Sobre ---
          _SectionHeader(label: 'Sobre'),
          const Gap(10),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Sobre o Nexa',
            subtitle: 'Versão 1.0.0',
            trailing: Icon(Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withOpacity(0.35)),
            onTap: _showAboutDialog,
          ),
        ],
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
          Icon(Icons.edit_outlined,
              color: colorScheme.onPrimary.withOpacity(0.6), size: 18),
        ],
      ),
    );
  }

  void _showCurrencyPicker(ColorScheme colorScheme) {
    final currencies = [
      {'code': 'BRL', 'name': 'Real Brasileiro', 'symbol': 'R\$'},
      {'code': 'USD', 'name': 'Dólar Americano', 'symbol': '\$'},
      {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusModal)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingScreen, vertical: 4),
              child: Text('Selecionar moeda',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface)),
            ),
            const Divider(height: 16),
            ...currencies.map((c) => ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.08),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusChip)),
                    child: Center(
                        child: Text(c['symbol'] ?? '',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary))),
                  ),
                  title: Text(c['code'] ?? '',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface)),
                  subtitle: Text(c['name'] ?? '',
                      style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.5))),
                  trailing: _selectedCurrency == c['code']
                      ? Icon(Icons.check_circle_rounded,
                          color: colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _selectedCurrency = c['code'] ?? '');
                    Navigator.pop(ctx);
                  },
                )),
            const Gap(8),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

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
